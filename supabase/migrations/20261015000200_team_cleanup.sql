-- A team with nobody left in it is gone too, whichever way the last member
-- was removed: the delete-account function, the dashboard, or the admin API.
create or replace function public.drop_empty_team()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where team_id = old.team_id) then
    delete from public.teams where id = old.team_id;
  end if;
  return old;
end;
$$;

create trigger profiles_drop_empty_team
  after delete on public.profiles
  for each row execute function public.drop_empty_team();
