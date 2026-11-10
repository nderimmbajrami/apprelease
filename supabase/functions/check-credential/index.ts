// check-credential — tests a stored Google Play service account against
// Google and says exactly what is still missing, with the link to fix it.
// The same for an App Store Connect key, a Slack bot and a Jira account.
//
// Called from the console with the user's token. Reads the secret with
// SECRETS_KEY (service role), signs the service-account JWT with WebCrypto,
// opens an edit for each of the team's Android apps and classifies the
// answer. No third-party library; the same calls the runner makes.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { preflight, reply } from "../_shared/cors.ts";

const API = "https://androidpublisher.googleapis.com/androidpublisher/v3";
const enc = new TextEncoder();
const b64url = (data: ArrayBuffer | string) => {
  const bytes = typeof data === "string" ? enc.encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};

function pemToDer(pem: string): ArrayBuffer {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(body);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out.buffer;
}

async function accessToken(sa: Record<string, string>): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8", pemToDer(sa.private_key), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(JSON.stringify({
    iss: sa.client_email, scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: sa.token_uri, iat: now, exp: now + 600,
  }));
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(`${header}.${payload}`));
  const assertion = `${header}.${payload}.${b64url(sig)}`;
  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  if (!res.ok) throw new Error(`token exchange ${res.status}: ${await res.text()}`);
  return (await res.json()).access_token;
}

type Check = { package: string; status: string; message: string; link?: string };

// ---------------------------------------------------------- App Store Connect

async function ascToken(issuerId: string, keyId: string, p8: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8", pemToDer(p8), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const payload = b64url(JSON.stringify({ iss: issuerId, iat: now, exp: now + 600, aud: "appstoreconnect-v1" }));
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, enc.encode(`${header}.${payload}`));
  return `${header}.${payload}.${b64url(sig)}`;
}

async function checkBundle(token: string, bundleId: string): Promise<Check> {
  const res = await fetch(
    `https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=${encodeURIComponent(bundleId)}&limit=1`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  const text = await res.text();
  let message = text;
  try { message = (JSON.parse(text).errors ?? []).map((e: { title: string; detail: string }) => `${e.title}: ${e.detail}`).join("; ") || text; } catch { /* keep */ }
  if (res.status === 401) {
    return { package: bundleId, status: "invalid_key", message: "Apple rejected the key. Check the Issuer ID, the Key ID and that the .p8 belongs to them.", link: "https://appstoreconnect.apple.com/access/integrations/api" };
  }
  if (res.status === 403) {
    return { package: bundleId, status: "not_invited", message: "The key's role is too low. Create a key with the App Manager role.", link: "https://appstoreconnect.apple.com/access/integrations/api" };
  }
  if (!res.ok) return { package: bundleId, status: "error", message: `${res.status}: ${message}` };
  const data = JSON.parse(text).data ?? [];
  if (!data.length) {
    return { package: bundleId, status: "unknown_package", message: `App Store Connect has no app with bundle identifier ${bundleId}. Create the app record there first.`, link: "https://appstoreconnect.apple.com/apps" };
  }
  return { package: bundleId, status: "ok", message: `App Store Connect accepts uploads for ${data[0].attributes?.name ?? bundleId}.` };
}

async function checkPackage(token: string, pkg: string, projectId: string): Promise<Check> {
  const res = await fetch(`${API}/applications/${pkg}/edits`, {
    method: "POST", headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: "{}",
  });
  const text = await res.text();
  let message = text;
  try { message = JSON.parse(text).error?.message ?? text; } catch { /* keep text */ }
  if (res.ok) {
    const editId = JSON.parse(text).id;
    await fetch(`${API}/applications/${pkg}/edits/${editId}`, { method: "DELETE", headers: { Authorization: `Bearer ${token}` } });
    return { package: pkg, status: "ok", message: "Google Play accepts uploads from this account." };
  }
  if (res.status === 403 && /has not been used|is disabled/.test(message)) {
    return {
      package: pkg, status: "api_disabled",
      message: "The Google Play Android Developer API is switched off in the Cloud project that owns this service account.",
      link: `https://console.developers.google.com/apis/api/androidpublisher.googleapis.com/overview?project=${projectId}`,
    };
  }
  if (res.status === 403 || res.status === 401) {
    return {
      package: pkg, status: "not_invited",
      message: "Google Play does not allow this account to release the app. Invite it under Users and permissions with release rights. A fresh invitation can take a few minutes to apply.",
      link: "https://play.google.com/console/developers",
    };
  }
  if (res.status === 404) {
    return {
      package: pkg, status: "unknown_package",
      message: `Google Play has no app with package name ${pkg} in this developer account, or the first bundle was never uploaded by hand.`,
      link: "https://play.google.com/console/developers",
    };
  }
  return { package: pkg, status: "error", message: `${res.status}: ${message}` };
}

// ------------------------------------------------------------ Slack and Jira

// The bot token, its two scopes, and that the bot sits in the channel.
// Nothing is posted: a check must not put a message in front of QA.
async function checkSlack(token: string, channel: string): Promise<Check[]> {
  const call = async (method: string, params: Record<string, string>) => {
    const res = await fetch(`https://slack.com/api/${method}`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(params),
    });
    return { scopes: (res.headers.get("x-oauth-scopes") ?? "").split(",").map((s) => s.trim()), body: await res.json() };
  };
  const apps = "https://api.slack.com/apps";
  const auth = await call("auth.test", {});
  if (!auth.body.ok) {
    return [{ package: "Slack", status: "invalid_key", message: `Slack refused the bot token (${auth.body.error}). Use the Bot User OAuth Token, the one that starts with xoxb-.`, link: apps }];
  }
  const checks: Check[] = [{ package: "Slack", status: "ok", message: `Connected to ${auth.body.team} as ${auth.body.user}.` }];
  const missing = ["chat:write", "files:write"].filter((s) => !auth.scopes.includes(s));
  if (missing.length) {
    checks.push({ package: "Permissions", status: "not_invited", message: `The bot lacks ${missing.join(" and ")}. Add under OAuth & Permissions → Bot Token Scopes, then reinstall the app to the workspace.`, link: apps });
  }
  // Needs channels:read, which the bot does not have to have: only a clear
  // answer counts, anything else is left to the first build.
  const info = await call("conversations.info", { channel });
  if (info.body.ok) {
    checks.push(info.body.channel?.is_member
      ? { package: `#${info.body.channel.name}`, status: "ok", message: "The bot is in the channel and can post there." }
      : { package: `#${info.body.channel?.name ?? channel}`, status: "not_invited", message: `The bot is not in the channel. In the channel, type /invite @${auth.body.user}.` });
  } else if (info.body.error === "channel_not_found") {
    checks.push({ package: channel, status: "unknown_package", message: `Slack shows this bot no channel with that ID. Copy the Channel ID from the bottom of the channel details, and for a private channel invite the bot first: /invite @${auth.body.user}.` });
  } else {
    checks.push({ package: channel, status: "ok", message: `The channel is checked with the first build. Make sure the bot is in it: /invite @${auth.body.user}.` });
  }
  return checks;
}

// The account, and that the status exists in the projects it should move
// tickets in.
async function checkJira(meta: Record<string, string>, token: string): Promise<Check[]> {
  let site = (meta.site ?? "").trim();
  if (!site.includes("://")) site = `https://${site}`;
  site = new URL(site).origin;
  const headers = { Authorization: `Basic ${btoa(`${meta.email}:${token}`)}`, Accept: "application/json" };
  const tokens = "https://id.atlassian.com/manage-profile/security/api-tokens";
  let me: Response;
  try {
    me = await fetch(`${site}/rest/api/3/myself`, { headers });
  } catch (e) {
    return [{ package: "Jira", status: "error", message: `${site} did not answer: ${e}` }];
  }
  if (me.status === 401 || me.status === 403) {
    return [{ package: "Jira", status: "invalid_key", message: "Jira refused the email and API token. The email must be the Atlassian account the token was created with.", link: tokens }];
  }
  if (!me.ok) return [{ package: "Jira", status: "error", message: `${site} answered ${me.status}. Check the site address.` }];
  const who = await me.json();
  const checks: Check[] = [{ package: "Jira", status: "ok", message: `Connected to ${site} as ${who.displayName ?? meta.email}.` }];

  const wanted = (meta.status ?? "").trim().toLowerCase();
  const projects = (meta.projects ?? "").split(/[,\s]+/).filter((p) => p);
  for (const key of projects) {
    const res = await fetch(`${site}/rest/api/3/project/${encodeURIComponent(key)}/statuses`, { headers });
    if (res.status === 404) {
      checks.push({ package: key, status: "unknown_package", message: `Jira has no project with the key ${key}, or this account cannot see it.` });
      continue;
    }
    if (!res.ok) { checks.push({ package: key, status: "error", message: `Jira answered ${res.status}.` }); continue; }
    const names = new Set<string>();
    for (const type of await res.json()) for (const s of type.statuses ?? []) names.add(s.name);
    checks.push([...names].some((n) => n.toLowerCase() === wanted)
      ? { package: key, status: "ok", message: `Tickets can move to "${meta.status}".` }
      : { package: key, status: "unknown_package", message: `${key} has no status named "${meta.status}". It has: ${[...names].join(", ")}.` });
  }
  if (!projects.length) {
    const res = await fetch(`${site}/rest/api/3/status`, { headers });
    if (res.ok) {
      const names: string[] = [...new Set((await res.json()).map((s: { name: string }) => s.name))] as string[];
      checks.push(names.some((n) => n.toLowerCase() === wanted)
        ? { package: meta.status, status: "ok", message: "Jira has a status with this name." }
        : { package: meta.status, status: "unknown_package", message: `Jira has no status named "${meta.status}". Use the name exactly as the board shows it.` });
    }
  }
  return checks;
}

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return reply(401, { error: "Unauthorized" });

  const { credential_id } = await req.json();
  // RLS: the user only sees their team's credential.
  const { data: credential } = await userClient.from("credentials").select("*").eq("id", credential_id).maybeSingle();
  if (!credential) return reply(404, { error: "unknown credential" });
  if (!["googlePlayServiceAccount", "appStoreConnectKey", "slack", "jira"].includes(credential.kind)) {
    return reply(400, { error: "only store accounts and connections can be checked" });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: rows, error } = await admin.rpc("read_credential_secret", { p_credential_id: credential_id, p_key: Deno.env.get("SECRETS_KEY") });
  if (error || !rows?.length) return reply(500, { error: error?.message ?? "secret unreadable" });
  const fields = JSON.parse(rows[0].fields_json);

  if (credential.kind === "slack") {
    return reply(200, { checks: await checkSlack(fields.token, credential.meta?.channel ?? "") });
  }
  if (credential.kind === "jira") {
    try {
      return reply(200, { checks: await checkJira(credential.meta ?? {}, fields.token) });
    } catch (e) {
      return reply(200, { checks: [{ package: "Jira", status: "error", message: `${e}` }] });
    }
  }

  if (credential.kind === "appStoreConnectKey") {
    const hex: string = rows[0].file_bytes.startsWith("\\x") ? rows[0].file_bytes.slice(2) : rows[0].file_bytes;
    const p8 = new TextDecoder().decode(new Uint8Array(hex.match(/.{2}/g)!.map((h: string) => parseInt(h, 16))));
    let token: string;
    try {
      token = await ascToken(fields.issuerId, fields.keyId, p8);
    } catch (e) {
      return reply(200, { checks: [{ package: "*", status: "invalid_key", message: `The .p8 file could not be used to sign: ${e}` }] });
    }
    const { data: apps } = await userClient.from("apps").select("name, ios_bundle_id").eq("team_id", credential.team_id);
    const bundles = (apps ?? []).map((a) => a.ios_bundle_id).filter((b: string) => b);
    if (!bundles.length) return reply(200, { checks: [{ package: "*", status: "no_apps", message: "Add an application with an iOS bundle identifier first." }] });
    const checks: Check[] = [];
    for (const b of bundles) checks.push(await checkBundle(token, b));
    return reply(200, { checks });
  }

  const sa = JSON.parse(fields.json);

  let token: string;
  try {
    token = await accessToken(sa);
  } catch (e) {
    return reply(200, { checks: [{ package: "*", status: "invalid_key", message: `Google rejected the key: ${e}` }] });
  }

  const { data: apps } = await userClient.from("apps").select("name, android_package_name").eq("team_id", credential.team_id);
  const packages = (apps ?? []).map((a) => a.android_package_name).filter((p: string) => p);
  if (!packages.length) return reply(200, { checks: [{ package: "*", status: "no_apps", message: "Add an application with an Android package name first." }] });

  const checks: Check[] = [];
  for (const pkg of packages) checks.push(await checkPackage(token, pkg, sa.project_id));
  return reply(200, { checks, email: sa.client_email, project: sa.project_id });
});
