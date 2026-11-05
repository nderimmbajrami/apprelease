-- A fourth kind of credential: a file the build needs that the repository
-- leaves out (google-services.json, GoogleService-Info.plist, .env). The
-- file is the secret; meta holds its path in the repository.
alter table public.credentials drop constraint if exists credentials_kind_check;
alter table public.credentials add constraint credentials_kind_check
  check (kind in ('androidKeystore', 'googlePlayServiceAccount', 'appStoreConnectKey', 'buildFile'));
