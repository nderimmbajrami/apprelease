-- A monthly release allowance per team. Releases that went out or are on
-- their way count; cancelled, replaced and failed ones do not, so a broken
-- setup or a pile of superseded pushes never eats the allowance.
--
-- Raise one team's allowance:
--   update public.teams set monthly_release_limit = 100 where name = '...';
alter table public.teams
  add column if not exists monthly_release_limit integer not null default 30;

create or replace function public.releases_used(p_team uuid)
returns integer
language sql stable security definer set search_path = public
as $$
  select count(*)::int from public.releases
   where team_id = p_team
     and status in ('queued', 'running', 'succeeded')
     and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc'
$$;

-- What the console shows: {used, limit, resets_at}.
create or replace function public.release_usage()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select jsonb_build_object(
    'used', public.releases_used(t.id),
    'limit', t.monthly_release_limit,
    'resets_at', (date_trunc('month', now() at time zone 'utc') + interval '1 month') at time zone 'utc'
  )
  from public.teams t where t.id = public.my_team_id()
$$;
grant execute on function public.release_usage() to authenticated;

-- Enforced where every release is born, console and webhook alike.
create or replace function public.enforce_release_limit()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  lim  int;
  used int;
begin
  select monthly_release_limit into lim from public.teams where id = new.team_id;
  used := public.releases_used(new.team_id);
  if lim is not null and used >= lim then
    raise exception 'release_limit_reached'
      using errcode = 'P0001', detail = format('%s of %s releases used this month', used, lim);
  end if;
  return new;
end;
$$;

drop trigger if exists releases_limit on public.releases;
create trigger releases_limit before insert on public.releases
  for each row execute function public.enforce_release_limit();
