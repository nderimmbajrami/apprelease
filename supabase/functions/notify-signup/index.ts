// notify-signup — called by the console once a new account is verified.
// Sends the welcome mail to the person and tells publish@apprelease.store
// that someone registered. Runs once per account (profiles.welcomed_at).
//
//   supabase secrets set RESEND_API_KEY=re_...
//   supabase functions deploy notify-signup
import { createClient } from "jsr:@supabase/supabase-js@2";
import { preflight, reply } from "../_shared/cors.ts";

const FROM = "AppRelease <publish@apprelease.store>";
const TEAM_INBOX = "publish@apprelease.store";

async function send(to: string, subject: string, html: string, replyTo?: string) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM, to: [to], subject, html, reply_to: replyTo }),
  });
  if (!response.ok) throw new Error(`Resend ${response.status}: ${await response.text()}`);
}

const shell = (title: string, body: string) => `<!DOCTYPE html>
<html lang="en"><body style="margin:0;padding:0;background:#f4f4f1;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;color:#111;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f4f1;padding:32px 16px;"><tr><td align="center">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#fff;border:1px solid #e3e3de;border-radius:12px;">
<tr><td style="padding:28px 32px 0;font-size:15px;font-weight:700;">AppRelease</td></tr>
<tr><td style="padding:18px 32px 0;font-size:22px;font-weight:700;letter-spacing:-.4px;line-height:1.25;">${title}</td></tr>
<tr><td style="padding:12px 32px 28px;font-size:15px;line-height:1.6;color:#333;">${body}</td></tr>
</table></td></tr></table></body></html>`;

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user || !user.email) return reply(401, { error: "Unauthorized" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: profile } = await admin
    .from("profiles").select("name, welcomed_at").eq("id", user.id).single();
  if (!profile) return reply(404, { error: "No profile" });
  if (profile.welcomed_at) {
    return reply(200, { ok: true, already: true });
  }
  const name = (profile.name as string) || user.email.split("@")[0];

  await send(
    user.email,
    "Welcome to AppRelease",
    shell(`Welcome, ${name}.`, `
<p>Your account is ready. To publish an app, AppRelease needs four things from you. Have them at hand and the first release takes ten minutes:</p>
<ol style="padding-left:20px;">
  <li><b>The Git URL</b> of the Flutter project.</li>
  <li><b>The Android upload keystore</b> (.jks) with its passwords and key alias.</li>
  <li><b>A Google Play service account</b> JSON key, invited in Play Console with release permissions.</li>
  <li><b>An App Store Connect API key</b> (.p8, Key ID, Issuer ID) for iOS.</li>
</ol>
<p>Open <a href="https://publish.apprelease.store" style="color:#111;">publish.apprelease.store</a> and the setup checklist walks you through them.</p>
<p>Reply to this mail if anything is unclear. A person answers.</p>`),
    TEAM_INBOX,
  );

  await send(
    TEAM_INBOX,
    `New sign-up: ${name} (${user.email})`,
    shell("New AppRelease account", `
<p><b>${name}</b> &lt;${user.email}&gt; registered and confirmed their email.</p>
<p style="color:#666;">${new Date().toUTCString()} &middot; user ${user.id}</p>`),
    user.email,
  );

  await admin.from("profiles").update({ welcomed_at: new Date().toISOString() }).eq("id", user.id);
  return reply(200, { ok: true });
});
