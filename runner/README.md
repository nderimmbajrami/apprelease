# AppRelease runner

The machine that does the work: claims a queued release, checks the
repository out, builds, signs, uploads and streams the log back to the
console. Any Mac with Flutter and Xcode can be a runner; a Linux box can run
Android releases.

```
bin/runner.dart          the process: poll → claim → Pipeline.run()
lib/src/api.dart         the four Supabase calls it needs (REST, service role)
lib/src/config.dart      apprelease.yaml → WorkflowConfig
lib/src/pipeline.dart    the seven steps, the log sink, secret masking
lib/src/steps/           checkout · signing · versioning · publish
```

## Setting up a runner

```bash
# Toolchain
flutter doctor                         # Flutter + Xcode (for iOS) + Android SDK
pip3 install codemagic-cli-tools       # google-play, app-store-connect CLIs
brew install git

# The runner itself
cd runner
cp .env.example .env                   # fill in URL, service role key, SECRETS_KEY
dart pub get
dart run bin/runner.dart               # or --once to run a single release and exit
```

Keep the process alive with `launchd` (macOS) or `systemd` (Linux); it polls
every five seconds and runs one release at a time.

## What it needs from the stores

* **Google Play** — the service account JSON stored under Credentials,
  invited in Play Console with release permissions.
* **App Store Connect** — the API key (.p8, key id, issuer id) stored under
  Credentials. Signing is automatic: `xcodebuild -allowProvisioningUpdates`
  with the key resolves the certificate and profile.

## Secrets

The runner reads a credential's secret by calling `read_credential_secret`
with `SECRETS_KEY`. Files are written to a temporary directory that is
deleted when the release ends, pass or fail, and every password and private
key is masked in the log before it leaves the machine.
