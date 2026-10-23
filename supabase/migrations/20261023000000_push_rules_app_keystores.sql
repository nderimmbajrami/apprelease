-- Several push rules per app: "develop → internal + TestFlight",
-- "main → production + App Store review". Each rule is
--   { "branch": "develop", "platforms": ["android","ios"],
--     "track_android": "internal", "track_ios": "testflight" }
-- A branch may end in * ("release/*"). The single-branch columns stay and
-- mirror the first rule, for anything that still reads them.
alter table public.apps
  add column if not exists trigger_rules jsonb not null default '[]'::jsonb;

update public.apps
   set trigger_rules = jsonb_build_array(jsonb_build_object(
         'branch', trigger_branch,
         'platforms', to_jsonb(trigger_platforms),
         'track_android', trigger_track_android,
         'track_ios', trigger_track_ios))
 where trigger_rules = '[]'::jsonb;

-- A keystore usually belongs to one app. Optional: a shared key stays
-- unlinked. Deleting the app keeps the key.
alter table public.credentials
  add column if not exists app_id uuid references public.apps (id) on delete set null;
create index if not exists credentials_app_idx on public.credentials (app_id);
