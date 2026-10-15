// github-webhook — GitHub posts here on every push; we queue a release.
//
//   https://<ref>.supabase.co/functions/v1/github-webhook?app=<app id>
//
// No user token: GitHub signs the body with the app's webhook secret
// (X-Hub-Signature-256) and that is what we check. Deployed with
// --no-verify-jwt.
import { createClient } from "jsr:@supabase/supabase-js@2";

// Must match pipelineSteps() in the console and the runner.
const STEPS: Record<string, string[]> = {
  android: [
    "Check out repository", "Set up Flutter", "Get packages",
    "Fetch build number from Google Play", "Build app bundle",
    "Sign with upload key", "Upload to Google Play",
  ],
  ios: [
    "Check out repository", "Set up Flutter and Xcode", "Get packages",
    "Fetch signing files", "Fetch build number from App Store Connect",
    "Build ipa", "Upload to App Store Connect",
  ],
};

const enc = new TextEncoder();

async function validSignature(secret: string, body: string, header: string | null) {
  if (!header?.startsWith("sha256=")) return false;
  const key = await crypto.subtle.importKey(
    "raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, enc.encode(body)));
  const hex = Array.from(mac).map((b) => b.toString(16).padStart(2, "0")).join("");
  const given = header.slice(7);
  if (hex.length !== given.length) return false;
  let diff = 0;
  for (let i = 0; i < hex.length; i++) diff |= hex.charCodeAt(i) ^ given.charCodeAt(i);
  return diff === 0;
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });
  const appId = new URL(req.url).searchParams.get("app");
  if (!appId) return json(400, { error: "missing ?app=" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: app } = await admin.from("apps").select("*").eq("id", appId).maybeSingle();
  if (!app) return json(404, { error: "unknown app" });

  const body = await req.text();
  if (!(await validSignature(app.webhook_secret, body, req.headers.get("x-hub-signature-256")))) {
    return json(401, { error: "bad signature" });
  }

  const event = req.headers.get("x-github-event");
  if (event === "ping") return json(200, { ok: true, pong: true });
  if (event !== "push") return json(200, { ok: true, ignored: event });
  if (!app.trigger_enabled) return json(200, { ok: true, ignored: "triggers off" });

  const payload = JSON.parse(body);
  const ref: string = payload.ref ?? "";
  const sha: string = (payload.after ?? "").slice(0, 7);
  const pusher: string = payload.pusher?.name ?? payload.sender?.login ?? "GitHub";
  if (payload.deleted) return json(200, { ok: true, ignored: "deleted ref" });

  // What to release, and where.
  let branch: string;
  let version = "auto";          // the runner reads pubspec.yaml after checkout
  let production = false;
  if (ref.startsWith("refs/tags/")) {
    if (!app.trigger_tags) return json(200, { ok: true, ignored: "tags off" });
    branch = ref.slice("refs/tags/".length);
    const m = branch.match(/^v?(\d+\.\d+\.\d+)/);
    if (!m) return json(200, { ok: true, ignored: "tag is not a version" });
    version = m[1];
    production = true;
  } else if (ref === `refs/heads/${app.trigger_branch}`) {
    branch = app.trigger_branch;
  } else {
    return json(200, { ok: true, ignored: `ref ${ref}` });
  }

  const queued: string[] = [];
  for (const platform of app.trigger_platforms as string[]) {
    const track = production
      ? (platform === "android" ? "production" : "appStore")
      : (platform === "android" ? app.trigger_track_android : app.trigger_track_ios);
    const { data: number } = await admin.rpc("next_release_number", { p_app_id: app.id });
    const id = crypto.randomUUID();
    const { error } = await admin.from("releases").insert({
      id, app_id: app.id, team_id: app.team_id, number, platform, track,
      version_name: version, status: "queued", branch, commit: sha,
      started_by_name: `GitHub push by ${pusher}`,
    });
    if (error) return json(500, { error: error.message });
    await admin.from("release_steps").insert(
      STEPS[platform].map((name, i) => ({ id: `${id}-${i}`, release_id: id, name, position: i, status: "pending" })),
    );
    queued.push(`${platform} #${number} → ${track}`);
  }
  return json(200, { ok: true, queued });
});
