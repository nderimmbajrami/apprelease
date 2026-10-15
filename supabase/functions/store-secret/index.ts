// store-secret — writes a credential's public facts to `credentials` and its
// secret, encrypted, to `credential_secrets`.
//
// The client never gets the secret back; only the runner, which holds the
// same SECRETS_KEY, decrypts it. Deploy with:
//
//   supabase secrets set SECRETS_KEY=<32+ random bytes, base64>
//   supabase functions deploy store-secret
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });

  const body = await req.json();
  const { id, team_id, kind, name, meta, secret } = body;

  // The caller may only write into their own team.
  const { data: profile } = await userClient
    .from("profiles").select("team_id").eq("id", user.id).single();
  if (!profile || profile.team_id !== team_id) {
    return new Response("Forbidden", { status: 403 });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const key = Deno.env.get("SECRETS_KEY")!;

  const { error: credError } = await admin
    .from("credentials").insert({ id, team_id, kind, name, meta });
  if (credError) return new Response(credError.message, { status: 400 });

  // pgp_sym_encrypt runs in the database so the key never meets the bytes
  // anywhere but here and on the runner.
  const { error: secretError } = await admin.rpc("store_credential_secret", {
    p_credential_id: id,
    p_file_name: secret.file_name ?? null,
    p_file_base64: secret.file_base64 ?? null,
    p_fields_json: JSON.stringify(secret.fields ?? {}),
    p_key: key,
  });
  if (secretError) {
    await admin.from("credentials").delete().eq("id", id);
    return new Response(secretError.message, { status: 400 });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
