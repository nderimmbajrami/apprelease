# Supabase backend

Project: `sghlhghffuwmfhrbkjfy` (eu-central-1).

```
migrations/   schema, row level security, realtime, the claim/secret RPCs
functions/    store-secret    · encrypts a credential's secret on the way in
              delete-account  · someone removing their own account
```

## One-time setup

1. Create a project at supabase.com and note the **project ref**.
2. Link and push the schema:

   ```bash
   supabase link --project-ref <ref>
   supabase db push
   ```

3. A key for the credential secrets. Generate once, keep it in a password
   manager, give it to the function and to every runner — never to the app:

   ```bash
   openssl rand -base64 48
   supabase secrets set SECRETS_KEY=<that value>
   supabase functions deploy store-secret
   supabase functions deploy delete-account
   ```

4. Auth settings live in `config.toml` and are pushed with
   `supabase config push`: the site URL and redirect list point at
   publish.apprelease.store, and **email confirmation is off**, so a sign-up
   returns a session straight away, which is what the console expects.

5. Build the console with the project's URL and publishable key:

   ```bash
   flutter build web --release \
     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```

   Without these defines the console runs on in-memory demo data.

## How the pieces talk

| who | reads | writes |
| --- | --- | --- |
| console (anon key + user session) | its team's apps, releases, steps, logs, credentials (facts only) | apps, queued releases, cancel flag, credentials via `store-secret` |
| runner (service role) | queued releases (`claim_release`), `read_credential_secret` | release status, steps, logs, artifacts |

`credential_secrets` has RLS on and **no policies**, so no client token can
select from it. The service role bypasses RLS; that is the runner.

## Tables

```
teams · profiles
apps → releases → release_steps · release_logs
credentials → credential_secrets
runners
```

Realtime is on for `apps`, `releases`, `release_steps`, `release_logs` and
`credentials`, which is how the console sees a step turn green without
polling.
