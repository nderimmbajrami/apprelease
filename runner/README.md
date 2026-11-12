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
lib/src/steps/           checkout · signing · versioning · publish · qa · preview
lib/src/stores/          our own Google Play and App Store Connect clients
```

## Setting up a runner

```bash
# Toolchain — nothing beyond what Flutter itself needs
flutter doctor                         # Flutter + Xcode (for iOS) + Android SDK + git

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
  invited in Play Console with release permissions. The runner exchanges it
  for an OAuth token and talks to the Android Publisher API itself
  (`lib/src/stores/google_play.dart`): open edit, upload bundle, set track,
  commit. Build numbers come from the same API.
* **App Store Connect** — the API key (.p8, key id, issuer id) stored under
  Credentials. The runner signs its own ES256 tokens and uses the App Store
  Connect API for build numbers, processing status, TestFlight groups and
  review submission (`lib/src/stores/app_store_connect.dart`). The one
  thing the API cannot do is receive the binary, so the upload goes through
  Apple's `xcrun altool`, which ships with Xcode.

No third-party CLI is involved anywhere.

## QA builds

A release whose track is `qa` (Android) or `qaTestflight` (iOS) is a build
for the testers, not for a store (`lib/src/steps/qa.dart`):

* **Android** builds a signed APK instead of a bundle and skips Google Play.
  Its last step uploads the APK to the team's Slack channel.
* **iOS** goes to TestFlight as usual, never to review, and gets one more
  step that tells the Slack channel.
* Both then read the ticket keys (`DAMA-123`) from the message of the
  commit that was checked out and move those tickets in Jira to the
  configured status. Slack first: a ticket only moves once the build is in
  the channel. A ticket that cannot move is a warning and a second Slack
  message, not a failed build.

Slack and Jira are credentials of the kinds `slack` (bot token; meta
`channel`) and `jira` (API token; meta `site`, `email`, `status`,
`projects`). The app's own connection wins over a shared one; one linked
to another app is never used.

## Previews ("see it on my phone")

A release whose track is `preview` builds an uploaded project, for people
who made an app with AI and have no Git (`lib/src/steps/preview.dart`):

1. The zip is downloaded from the private `sources` bucket and unpacked.
   The project is the shallowest folder with a `pubspec.yaml`; its `build`
   and `.dart_tool` folders are thrown away.
2. `flutter build apk --release`. A project whose release build wants a
   `key.properties` that was not uploaded is built as debug instead.
3. `flutter build web`, with the base href of the address it will have. A
   project that cannot run in a browser loses the iPhone link, not the
   build.
4. Both are copied to `PREVIEW_DIR/<release id>/` and the release gets
   `preview_url`. The console draws the two QR codes from it. Folders older
   than `PREVIEW_KEEP_DAYS` are removed at the next publish.

A missing `android` or `web` folder is added with `flutter create`.

When the build is over, passed or failed, the zip is deleted from the
`sources` bucket: the next build of that app starts with a new upload.

The runner only writes files. Something has to serve `PREVIEW_DIR` at
`PREVIEW_BASE_URL`, over https (an iPhone will not open the app otherwise):

```bash
dart run bin/serve_previews.dart                 # serves PREVIEW_DIR on PREVIEW_PORT (8787)
cloudflared tunnel --url http://localhost:8787   # gives it a public https address
```

Put the address the tunnel prints into `PREVIEW_BASE_URL` and restart the
runner. A quick tunnel gets a new address every time it starts, and links
already handed out stop working; a named tunnel on your own domain
(`preview.apprelease.store`) keeps one address. A web host works as well:
sync `PREVIEW_DIR` to it and point `PREVIEW_BASE_URL` there.

Without `PREVIEW_DIR` and `PREVIEW_BASE_URL` a preview fails in its first
step and says so.

To try a zip without the console or Supabase:

```bash
dart run tool/preview_local.dart ~/Downloads/my_app.zip "My App"
```

Previews run a stranger's code on this machine. They are off for every
team until switched on (`teams.previews_enabled`, see the `previews`
migration).

## Secrets

The runner reads a credential's secret by calling `read_credential_secret`
with `SECRETS_KEY`. Files are written to a temporary directory that is
deleted when the release ends, pass or fail, and every password and private
key is masked in the log before it leaves the machine.
