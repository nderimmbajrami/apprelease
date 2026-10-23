-- Where a queued release stands, for the customer waiting on it. A team
-- sees only its own releases, so the queue across teams is counted here.
create or replace function public.release_queue(p_release uuid)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  r       public.releases;
  ahead   int;
  busy    int;
  online  int;
  avg_s   int;
begin
  select * into r from public.releases
   where id = p_release and team_id = public.my_team_id();
  if not found then return null; end if;

  -- Releases the runners will take before this one (oldest first).
  select count(*) into ahead from public.releases q
   where q.status = 'queued' and q.platform = r.platform
     and q.created_at < r.created_at;
  select count(*) into busy from public.releases q
   where q.status = 'running' and q.platform = r.platform;
  -- The runner reports every 30 s, also while it builds.
  select count(*) into online from public.runners w
   where r.platform = any (w.platforms)
     and w.last_seen_at > now() - interval '2 minutes';
  select coalesce(
           avg(extract(epoch from s.finished_at - s.started_at))::int,
           case when r.platform = 'ios' then 720 else 360 end)
    into avg_s
    from (select finished_at, started_at from public.releases
           where platform = r.platform and status = 'succeeded'
             and started_at is not null and finished_at is not null
           order by finished_at desc limit 20) s;

  return jsonb_build_object(
    'ahead', ahead, 'running', busy,
    'runners_online', online, 'avg_seconds', avg_s);
end;
$$;

grant execute on function public.release_queue(uuid) to authenticated;
