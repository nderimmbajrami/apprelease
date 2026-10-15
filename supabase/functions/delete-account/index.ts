// delete-account — the signed-in person removing themselves. The App Store
// requires it of any app people can register for. Deleting the auth user
// cascades to the profile; if they were the last member, the team and
// everything in it goes too.
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

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: profile } = await admin
    .from("profiles").select("team_id").eq("id", user.id).single();

  await admin.auth.admin.deleteUser(user.id);

  if (profile) {
    const { count } = await admin
      .from("profiles").select("id", { count: "exact", head: true })
      .eq("team_id", profile.team_id);
    if ((count ?? 0) === 0) {
      await admin.from("teams").delete().eq("id", profile.team_id);
    }
  }
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
