// Mail through Resend, and the alert the team gets for every new release.
// Needs RESEND_API_KEY (supabase secrets set RESEND_API_KEY=re_...).
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const FROM = "AppRelease <publish@apprelease.store>";
export const TEAM_INBOX = "publish@apprelease.store";

export async function send(to: string, subject: string, html: string, replyTo?: string) {
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

export const shell = (title: string, body: string) => `<!DOCTYPE html>
<html lang="en"><body style="margin:0;padding:0;background:#f4f4f1;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;color:#111;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f4f1;padding:32px 16px;"><tr><td align="center">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#fff;border:1px solid #e3e3de;border-radius:12px;">
<tr><td style="padding:28px 32px 0;font-size:15px;font-weight:700;">AppRelease</td></tr>
<tr><td style="padding:18px 32px 0;font-size:22px;font-weight:700;letter-spacing:-.4px;line-height:1.25;">${title}</td></tr>
<tr><td style="padding:12px 32px 28px;font-size:15px;line-height:1.6;color:#333;">${body}</td></tr>
</table></td></tr></table></body></html>`;

const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);

const TRACKS: Record<string, string> = {
  internal: "Internal testing", alpha: "Closed testing", beta: "Open testing",
  production: "Production", testflight: "TestFlight", appStore: "App Store review",
  qa: "QA build (APK in Slack)", qaTestflight: "QA build (TestFlight)",
};

// Tells the team inbox that releases were queued, and loudly so when no
// build machine for their platform has reported in: someone has to start one.
export async function alertQueued(admin: SupabaseClient, releaseIds: string[]) {
  if (!releaseIds.length) return;
  const { data: releases } = await admin.from("releases")
    .select("id, number, platform, track, branch, commit, started_by_name, app_id, team_id")
    .in("id", releaseIds).order("number");
  if (!releases?.length) return;
  const first = releases[0];
  const [{ data: app }, { data: team }, { data: owner }, { data: runners }, { data: usage }] = await Promise.all([
    admin.from("apps").select("name").eq("id", first.app_id).maybeSingle(),
    admin.from("teams").select("name, monthly_release_limit").eq("id", first.team_id).maybeSingle(),
    admin.from("profiles").select("name, email").eq("team_id", first.team_id).order("created_at").limit(1).maybeSingle(),
    admin.from("runners").select("name, platforms")
      .gt("last_seen_at", new Date(Date.now() - 2 * 60_000).toISOString()),
    admin.rpc("releases_used", { p_team: first.team_id }),
  ]);
  const platforms = [...new Set(releases.map((r) => r.platform))];
  const offline = platforms.filter((p) => !(runners ?? []).some((r) => (r.platforms ?? []).includes(p)));
  const appName = app?.name ?? "An app";

  const rows = releases.map((r) => `<li><b>#${r.number}</b> ${r.platform === "ios" ? "iOS" : "Android"} &rarr; ${esc(TRACKS[r.track] ?? r.track)} &middot; ${esc(r.branch)}${r.commit ? ` @ ${esc(r.commit)}` : ""}</li>`).join("");
  const machine = offline.length
    ? `<p style="padding:12px 14px;background:#fff1f0;border:1px solid #f3c2bd;border-radius:8px;color:#a1261b;"><b>No build machine is online for ${offline.map((p) => p === "ios" ? "iOS" : "Android").join(" and ")}.</b> The customer is waiting. Start the runner (tool/launchd.sh status) or the release stays queued.</p>`
    : `<p style="color:#2f7a3b;">A build machine is online and will pick it up.</p>`;

  await send(
    TEAM_INBOX,
    `${offline.length ? "Runner offline: " : ""}${appName} queued ${releases.length === 1 ? "a release" : `${releases.length} releases`}`,
    shell(`${esc(appName)} wants to release`, `
${machine}
<ul style="padding-left:20px;">${rows}</ul>
<p>Started by ${esc(first.started_by_name)}<br>
Team <b>${esc(team?.name)}</b> &middot; ${esc(owner?.name)} &lt;${esc(owner?.email)}&gt;<br>
${usage ?? "?"} of ${team?.monthly_release_limit ?? "?"} releases used this month</p>
<p><a href="https://publish.apprelease.store/#/apps/${first.app_id}" style="color:#111;">Open in the console</a></p>`),
    owner?.email,
  );
}
