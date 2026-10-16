// check-credential — tests a stored Google Play service account against
// Google and says exactly what is still missing, with the link to fix it.
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
  if (!["googlePlayServiceAccount", "appStoreConnectKey"].includes(credential.kind)) {
    return reply(400, { error: "only store accounts can be checked" });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: rows, error } = await admin.rpc("read_credential_secret", { p_credential_id: credential_id, p_key: Deno.env.get("SECRETS_KEY") });
  if (error || !rows?.length) return reply(500, { error: error?.message ?? "secret unreadable" });
  const fields = JSON.parse(rows[0].fields_json);

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
