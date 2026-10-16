-- A release is written in two inserts (row, then steps). The runner must
-- not claim it in between, so the claim waits for the steps to exist.
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
     select id from public.releases q
      where q.status = 'queued'
        and q.platform = any (p_platforms)
        and exists (select 1 from public.release_steps s where s.release_id = q.id)
      order by q.created_at
      for update skip locked
      limit 1
   )
  returning * into claimed;
  return claimed;
end;
$$;
