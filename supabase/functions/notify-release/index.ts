// notify-release — called by the console right after it queued a release.
// Mails publish@apprelease.store who wants to release what, and whether a
// build machine is online to do it.
//
//   supabase functions deploy notify-release
import { createClient } from "jsr:@supabase/supabase-js@2";
import { preflight, reply } from "../_shared/cors.ts";
import { alertQueued } from "../_shared/mail.ts";

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return reply(401, { error: "Unauthorized" });

  const { release_id } = await req.json().catch(() => ({}));
  if (typeof release_id !== "string") return reply(400, { error: "release_id required" });
  // Row-level security: only a release of the caller's own team is found.
  const { data: own } = await userClient.from("releases").select("id").eq("id", release_id).maybeSingle();
  if (!own) return reply(404, { error: "Unknown release" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  await alertQueued(admin, [release_id]);
  return reply(200, { ok: true });
});
