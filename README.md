# AppRelease

**Ship your Flutter app to both stores.** AppRelease builds, signs and
publishes Flutter apps to Google Play and the App Store from one
`apprelease.yaml`. Flutter first; React Native next.

```
landing_src/   the marketing site and the docs, as page fragments
landing/       the built site — upload this folder to apprelease.store
lib/           the console (Flutter web) — publish.apprelease.store
supabase/      schema, row level security, Edge Functions
runner/        the build machine side (Dart CLI)
tool/          build and deploy scripts
```

## The three parts

| part | lives at | what it does |
| --- | --- | --- |
| **Landing + docs** | apprelease.store | Explains the product. Static HTML on Hostinger, no build step on the server. |
| **Console** | publish.apprelease.store | Where apps, credentials and releases live. Flutter web, Riverpod, go_router, Supabase. |
| **Runner** | a Mac (or Linux box for Android) | Claims a queued release, clones, builds, signs, uploads, streams the log. |

A release starts in the console. The runner claims it through an atomic
`claim_release` call, reads the credentials the workflow names, runs the
scripts from `apprelease.yaml`, publishes the artifact and writes every step
and log line back. The console sees each change through Supabase realtime.

## Landing site

Pages are fragments with a short front matter in `landing_src/pages/`;
header, footer and the docs sidebar are partials. The generator assembles
`landing/`, colours the code blocks and writes the sitemap:

```bash
python3 tool/build_landing.py     # or: tool/serve_landing.sh (builds + serves on :8080)
tool/package_landing.sh           # dist/apprelease-landing-<date>.zip for Hostinger
```

Upload the **contents** of `landing/` (including `.htaccess`) to the domain's
`public_html`. Pages are folders (`/pricing/index.html`), so nothing has to be
rewritten on the server.

## Console

```bash
flutter pub get
dart run build_runner watch       # regenerate *.g.dart while developing
flutter gen-l10n                  # after editing lib/l10n/app_en.arb
flutter test
flutter run -d chrome             # in-memory demo data: demo@apprelease.store / demo1234
```

Without Supabase defines the console runs on the in-memory backend: a demo
app, three past releases, and a **simulated runner** that walks a new release
through its steps so the whole flow can be tried. With defines it talks to
the real project:

```bash
SUPABASE_URL=https://<ref>.supabase.co \
SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
tool/build_web.sh                 # → dist/apprelease-console-<stamp>.zip
```

Upload that zip's contents to the `public_html` of the `publish` subdomain.
The script stamps `main.dart.js` per build so no browser serves a stale one,
and writes the `.htaccess` the Flutter web app needs on Apache.

### Architecture

Feature-first, the same shape as the Baurapport app. Each feature owns its
three layers; shared code lives in `core/`.

```
lib/
  main.dart                       bootstrap: prefs, Supabase, ProviderScope
  l10n/app_en.arb                 every UI string
  src/
    app/app.dart                  MaterialApp.router: theme, router
    core/
      config/app_config.dart      --dart-define switches
      data/                       backend switch, InMemoryTable, watchQuery (realtime)
      theme/                      colours, Material 3 themes, mono text, breakpoints
      widgets/                    AppShell, AppCard, AppPill, PageHeader, StatTile, …
    routing/                      AppRoute enum + goRouterProvider with the auth redirect
    features/
      auth/         sign in / sign up, AppUser
      apps/         AppProject: repository, platforms, ids
      releases/     Release, steps, log lines; the simulated runner in Local*
      credentials/  keystores, service accounts, App Store Connect keys
      config/       ReleaseConfig → apprelease.yaml
      home/         dashboard
      settings/     profile, theme, sign out, delete account
```

Rules of thumb:

- **presentation → data → domain.** Screens read controllers, controllers read
  repositories, repositories return domain models. Domain is pure Dart.
- **Every repository has two implementations** behind one interface — the real
  one and an in-memory one — selected by `backendProvider`. Tests use the
  in-memory one, so nothing reaches the network.
- **Repositories expose streams** (`watchX()`) plus future-returning
  mutations. Supabase repositories re-run their query on realtime events.
- **Providers are generated** with `@riverpod`. Repositories and app-wide
  state are `keepAlive`; screen state auto-disposes.
- **Controllers guard `ref.mounted`** before writing state after an await.
- **Navigate by name**: `context.goNamed(AppRoute.release.name, …)`.

## Backend and runner

See [supabase/README.md](supabase/README.md) for the one-time project setup
and [runner/README.md](runner/README.md) for turning a Mac into a runner.
Both need the same `SECRETS_KEY`; the console never sees it.

## Status

| | done | next |
| --- | --- | --- |
| Landing + docs | home, pricing, FAQ, contact, legal, docs (Flutter quick start, Android/iOS signing, Google Play, App Store Connect, YAML reference) | screenshots of the console, blog |
| Console | auth, apps, releases with live steps and log, credentials, generated `apprelease.yaml`, settings; widget tests | team invites, webhooks/triggers, email notifications, Stripe |
| Runner | claim → checkout → toolchain → packages → signing → versioning → build → publish; secrets masked; cleanup | FVM, caching, artifact upload to storage, Linux runner image |
| React Native | — | quick start + runner steps |
