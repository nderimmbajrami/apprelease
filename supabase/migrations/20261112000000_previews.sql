-- Previews: "see it on my phone" for people who built an app with AI and
-- have no Git. They upload the project as a zip; the build machine makes
-- an Android APK and a web version and hands back two links, shown in the
-- console as QR codes.
--
--   apps.source_zip      where the uploaded zip sits in the 'sources' bucket
--   releases.preview_url the folder the build machine published, with a
--                        trailing slash: <preview_url><name>.apk is the
--                        Android app, <preview_url>web/ opens on an iPhone
--   releases.track       'preview' (free text already, no change)
--
-- A preview runs a stranger's code on the build machine, so it is switched
-- on per team while the feature is new:
--   update public.teams set previews_enabled = true where name = '...';
--   update public.teams t set previews_enabled = true
--     from public.profiles p where p.team_id = t.id and p.email = '...';
alter table public.teams
  add column if not exists previews_enabled boolean not null default false;
alter table public.apps
  add column if not exists source_zip text;
alter table public.releases
  add column if not exists preview_url text;

-- Enforced where every release is born.
create or replace function public.enforce_previews_enabled()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.track = 'preview' and not coalesce(
       (select previews_enabled from public.teams where id = new.team_id), false) then
    raise exception 'previews_not_enabled' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists releases_previews on public.releases;
create trigger releases_previews before insert on public.releases
  for each row execute function public.enforce_previews_enabled();

-- The uploaded zips. Private: a team reads and writes its own folder
-- (<team id>/<app id>.zip); the build machine reads with the service role
-- and deletes the zip when its build is over, so the bucket only holds
-- what is waiting to be built.
insert into storage.buckets (id, name, public, file_size_limit)
values ('sources', 'sources', false, 52428800)
on conflict (id) do nothing;

drop policy if exists "team reads sources"   on storage.objects;
drop policy if exists "team adds sources"    on storage.objects;
drop policy if exists "team changes sources" on storage.objects;
drop policy if exists "team removes sources" on storage.objects;

create policy "team reads sources" on storage.objects for select to authenticated
  using (bucket_id = 'sources' and (storage.foldername(name))[1] = public.my_team_id()::text);
create policy "team adds sources" on storage.objects for insert to authenticated
  with check (bucket_id = 'sources' and (storage.foldername(name))[1] = public.my_team_id()::text);
create policy "team changes sources" on storage.objects for update to authenticated
  using (bucket_id = 'sources' and (storage.foldername(name))[1] = public.my_team_id()::text)
  with check (bucket_id = 'sources' and (storage.foldername(name))[1] = public.my_team_id()::text);
create policy "team removes sources" on storage.objects for delete to authenticated
  using (bucket_id = 'sources' and (storage.foldername(name))[1] = public.my_team_id()::text);
