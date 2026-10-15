-- Called by the store-secret function (service role) with the SECRETS_KEY.
create or replace function public.store_credential_secret(
  p_credential_id uuid,
  p_file_name     text,
  p_file_base64   text,
  p_fields_json   text,
  p_key           text
)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
begin
  insert into public.credential_secrets (credential_id, file_name, file_cipher, fields_cipher)
  values (
    p_credential_id,
    p_file_name,
    case when p_file_base64 is null then null
         else pgp_sym_encrypt_bytea(decode(p_file_base64, 'base64'), p_key) end,
    pgp_sym_encrypt(p_fields_json, p_key)
  );
end;
$$;

-- Called by the runner (service role) when a release needs a credential.
create or replace function public.read_credential_secret(p_credential_id uuid, p_key text)
returns table (file_name text, file_bytes bytea, fields_json text)
language sql security definer set search_path = public, extensions
as $$
  select file_name,
         case when file_cipher is null then null else pgp_sym_decrypt_bytea(file_cipher, p_key) end,
         pgp_sym_decrypt(fields_cipher, p_key)
    from public.credential_secrets
   where credential_id = p_credential_id
$$;

revoke all on function public.store_credential_secret(uuid, text, text, text, text) from public, anon, authenticated;
revoke all on function public.read_credential_secret(uuid, text) from public, anon, authenticated;
