-- AppRelease — schema, row level security, realtime.
--
--   teams · profiles
--   apps → releases → release_steps · release_logs
--   credentials → credential_secrets (encrypted, never readable by a client)
--   runners
--
-- Everything a client reads is scoped to its team through RLS. The runner
-- uses the service role and bypasses RLS; it is the only thing that reads
-- credential_secrets.

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------ teams

create table public.teams (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  plan        text not null default 'free',
  created_at  timestamptz not null default now()
);

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  team_id     uuid not null references public.teams (id) on delete cascade,
  name        text not null default '',
  email       text not null default '',
  created_at  timestamptz not null default now()
);

create index profiles_team_idx on public.profiles (team_id);

-- The caller's team, used by every policy below.
create or replace function public.my_team_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select team_id from public.profiles where id = auth.uid()
$$;

-- A new account gets its own team and a profile, with the name from the
-- sign-up metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  new_team uuid;
begin
  insert into public.teams (name)
  values (coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)))
  returning id into new_team;

  insert into public.profiles (id, team_id, name, email)
  values (new.id, new_team, coalesce(new.raw_user_meta_data ->> 'name', ''), coalesce(new.email, ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------------- apps

create table public.apps (
  id                    uuid primary key,
  team_id               uuid not null references public.teams (id) on delete cascade,
  name                  text not null,
  repo_url              text not null,
  branch                text not null default 'main',
  project_type          text not null default 'flutter' check (project_type in ('flutter', 'reactNative')),
  platforms             text[] not null default '{android,ios}',
  android_package_name  text not null default '',
  ios_bundle_id         text not null default '',
  flutter_version       text not null default 'stable',
  release_count         integer not null default 0,
  last_release_at       timestamptz,
  created_at            timestamptz not null default now()
);

create index apps_team_idx on public.apps (team_id);

-- --------------------------------------------------------------- releases

create table public.releases (
  id                uuid primary key,
  app_id            uuid not null references public.apps (id) on delete cascade,
  team_id           uuid not null references public.teams (id) on delete cascade,
  number            integer not null,
  platform          text not null check (platform in ('android', 'ios')),
  track             text not null,
  version_name      text not null,
  build_number      integer,
  status            text not null default 'queued'
                    check (status in ('queued', 'running', 'succeeded', 'failed', 'cancelled')),
  branch            text not null,
  commit            text,
  started_by_name   text not null default '',
  runner_id         uuid,
  cancel_requested  boolean not null default false,
  artifacts         text[] not null default '{}',
  error_message     text,
  created_at        timestamptz not null default now(),
  started_at        timestamptz,
  finished_at       timestamptz,
  unique (app_id, number)
);

create index releases_team_created_idx on public.releases (team_id, created_at desc);
create index releases_queue_idx on public.releases (status, created_at) where status = 'queued';

create table public.release_steps (
  id           text primary key,
  release_id   uuid not null references public.releases (id) on delete cascade,
  name         text not null,
  position     integer not null,
  status       text not null default 'pending'
               check (status in ('pending', 'running', 'succeeded', 'failed', 'skipped')),
  started_at   timestamptz,
  finished_at  timestamptz
);

create index release_steps_release_idx on public.release_steps (release_id, position);

create table public.release_logs (
  id          bigint generated always as identity primary key,
  release_id  uuid not null references public.releases (id) on delete cascade,
  seq         integer not null,
  step_id     text,
  at          timestamptz not null default now(),
  level       text not null default 'info'
              check (level in ('info', 'command', 'warning', 'error', 'success')),
  text        text not null
);

create index release_logs_release_idx on public.release_logs (release_id, seq);

-- Keeps the denormalised counters on apps in step with releases.
create or replace function public.touch_app_release_count()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update public.apps a
     set release_count = (select count(*) from public.releases r where r.app_id = a.id),
         last_release_at = (select max(created_at) from public.releases r where r.app_id = a.id)
   where a.id = coalesce(new.app_id, old.app_id);
  return null;
end;
$$;

create trigger releases_touch_app
  after insert or delete on public.releases
  for each row execute function public.touch_app_release_count();

-- ------------------------------------------------------------ credentials

create table public.credentials (
  id          uuid primary key,
  team_id     uuid not null references public.teams (id) on delete cascade,
  kind        text not null
              check (kind in ('androidKeystore', 'googlePlayServiceAccount', 'appStoreConnectKey')),
  name        text not null,
  meta        jsonb not null default '{}',
  created_at  timestamptz not null default now(),
  unique (team_id, name)
);

create index credentials_team_idx on public.credentials (team_id);

-- The secret half. Written only by the store-secret function (service role),
-- read only by the runner (service role). No client policy exists on
-- purpose: with RLS enabled and no policies, a client sees nothing.
create table public.credential_secrets (
  credential_id  uuid primary key references public.credentials (id) on delete cascade,
  file_name      text,
  -- pgp_sym_encrypt(...) with the SECRETS_KEY held by the function and the runner.
  file_cipher    bytea,
  fields_cipher  bytea not null,
  created_at     timestamptz not null default now()
);

-- ---------------------------------------------------------------- runners

create table public.runners (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  team_id       uuid references public.teams (id) on delete cascade,  -- null = shared
  platforms     text[] not null default '{android,ios}',
  last_seen_at  timestamptz,
  created_at    timestamptz not null default now()
);

-- ---------------------------------------------------------- row security

alter table public.teams              enable row level security;
alter table public.profiles           enable row level security;
alter table public.apps               enable row level security;
alter table public.releases           enable row level security;
alter table public.release_steps      enable row level security;
alter table public.release_logs       enable row level security;
alter table public.credentials        enable row level security;
alter table public.credential_secrets enable row level security;
alter table public.runners            enable row level security;

create policy "own team"        on public.teams    for select using (id = public.my_team_id());
create policy "own profile"     on public.profiles for select using (id = auth.uid() or team_id = public.my_team_id());
create policy "edit own name"   on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

create policy "team apps"       on public.apps for all
  using (team_id = public.my_team_id()) with check (team_id = public.my_team_id());

create policy "team releases"   on public.releases for all
  using (team_id = public.my_team_id()) with check (team_id = public.my_team_id());

create policy "team steps"      on public.release_steps for all
  using (exists (select 1 from public.releases r where r.id = release_id and r.team_id = public.my_team_id()))
  with check (exists (select 1 from public.releases r where r.id = release_id and r.team_id = public.my_team_id()));

create policy "team logs"       on public.release_logs for select
  using (exists (select 1 from public.releases r where r.id = release_id and r.team_id = public.my_team_id()));

create policy "team credentials" on public.credentials for all
  using (team_id = public.my_team_id()) with check (team_id = public.my_team_id());

create policy "team runners"    on public.runners for select
  using (team_id is null or team_id = public.my_team_id());

-- ---------------------------------------------------------------- realtime

alter publication supabase_realtime add table public.apps;
alter publication supabase_realtime add table public.releases;
alter publication supabase_realtime add table public.release_steps;
alter publication supabase_realtime add table public.release_logs;
alter publication supabase_realtime add table public.credentials;

-- The runner claims one queued release atomically.
create or replace function public.claim_release(p_runner uuid, p_platforms text[])
returns public.releases
language plpgsql security definer set search_path = public
as $$
declare
  claimed public.releases;
begin
  update public.releases r
     set status = 'running', runner_id = p_runner, started_at = now()
   where r.id = (
     select id from public.releases
      where status = 'queued' and platform = any (p_platforms)
      order by created_at
      for update skip locked
      limit 1
   )
  returning * into claimed;
  return claimed;
end;
$$;

revoke all on function public.claim_release(uuid, text[]) from public, anon, authenticated;
