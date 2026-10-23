#!/usr/bin/env bash
# Keeps the runner going on a Mac without a terminal open: two background
# services, one for Android and one for iOS, so both stores build at once.
# macOS starts them at login and restarts them if they crash.
#
#   tool/launchd.sh install     compile the runner and start both services
#   tool/launchd.sh status      are they running, last log lines
#   tool/launchd.sh restart     after pulling new runner code
#   tool/launchd.sh uninstall   stop and remove both
#
# Reads runner/.env for the Supabase URL and keys. Stop any runner you
# started by hand first, or it will compete for the same queue.
set -euo pipefail

cd "$(dirname "$0")/.."
RUNNER_DIR="$(pwd)"
AGENTS="$HOME/Library/LaunchAgents"
LOGS="$RUNNER_DIR/logs"
BIN="$RUNNER_DIR/build/runner"
DOMAIN="gui/$(id -u)"
PLATFORMS=(android ios)
label() { echo "store.apprelease.runner.$1"; }

flutter_bin() {
  local f
  f="$(command -v flutter || true)"
  [[ -n "$f" ]] || { echo "flutter is not on PATH" >&2; exit 1; }
  dirname "$(readlink -f "$f" 2>/dev/null || echo "$f")"
}

compile() {
  [[ -f .env ]] || { echo "runner/.env is missing (see .env.example)" >&2; exit 1; }
  mkdir -p build "$LOGS"
  dart pub get >/dev/null
  dart compile exe bin/runner.dart -o "$BIN" >/dev/null
  echo "compiled $BIN"
}

plist() {
  local platform="$1" fbin path
  fbin="$(flutter_bin)"
  # Everything a build calls: flutter/dart, git, xcrun and CocoaPods.
  path="$fbin:$fbin/cache/dart-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$(label "$platform")</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>WorkingDirectory</key><string>$RUNNER_DIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>$path</string>
    <key>HOME</key><string>$HOME</string>
    <key>LANG</key><string>en_US.UTF-8</string>
    <key>LC_ALL</key><string>en_US.UTF-8</string>
    <key>RUNNER_NAME</key><string>$(scutil --get LocalHostName 2>/dev/null || hostname -s)-$platform</string>
    <key>RUNNER_PLATFORMS</key><string>$platform</string>
    <key>RUNNER_WORKSPACE</key><string>$RUNNER_DIR/workspace/$platform</string>
    <key>RUNNER_ID_FILE</key><string>.runner-id-$platform</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>15</integer>
  <key>ProcessType</key><string>Interactive</string>
  <key>StandardOutPath</key><string>$LOGS/runner-$platform.log</string>
  <key>StandardErrorPath</key><string>$LOGS/runner-$platform.log</string>
</dict>
</plist>
PLIST
}

stop_all() {
  for p in "${PLATFORMS[@]}"; do
    launchctl bootout "$DOMAIN/$(label "$p")" 2>/dev/null || true
  done
}

case "${1:-}" in
  install)
    if pgrep -f "bin/runner.dart" >/dev/null; then
      echo "A runner started by hand is still running (pgrep -f bin/runner.dart)."
      echo "Stop it first (Ctrl+C in its terminal), then run install again."
      exit 1
    fi
    compile
    mkdir -p "$AGENTS"
    stop_all
    for p in "${PLATFORMS[@]}"; do
      mkdir -p "$RUNNER_DIR/workspace/$p"
      plist "$p" > "$AGENTS/$(label "$p").plist"
      plutil -lint -s "$AGENTS/$(label "$p").plist"
      launchctl bootstrap "$DOMAIN" "$AGENTS/$(label "$p").plist"
      echo "started $(label "$p")"
    done
    echo "logs: $LOGS"
    ;;
  restart)
    compile
    for p in "${PLATFORMS[@]}"; do
      launchctl kickstart -k "$DOMAIN/$(label "$p")"
      echo "restarted $(label "$p")"
    done
    ;;
  status)
    for p in "${PLATFORMS[@]}"; do
      echo "== $(label "$p")"
      launchctl print "$DOMAIN/$(label "$p")" 2>/dev/null | grep -E "state =|pid =|last exit" || echo "   not loaded"
      tail -n 3 "$LOGS/runner-$p.log" 2>/dev/null | sed 's/^/   /' || true
    done
    ;;
  uninstall)
    stop_all
    for p in "${PLATFORMS[@]}"; do rm -f "$AGENTS/$(label "$p").plist"; done
    echo "removed both services"
    ;;
  plist)
    # Print what install would write, without installing anything.
    plist "${2:-ios}"
    ;;
  *)
    sed -n '2,12p' "$0"
    exit 1
    ;;
esac
