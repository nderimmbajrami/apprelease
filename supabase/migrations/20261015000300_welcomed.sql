-- When the welcome mail went out, so it goes out once.
alter table public.profiles add column if not exists welcomed_at timestamptz;
