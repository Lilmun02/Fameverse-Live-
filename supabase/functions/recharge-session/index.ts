import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const headers = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers });
}

function hex(bytes: Uint8Array) {
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return hex(new Uint8Array(digest));
}

function randomToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method-not-allowed" });

  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return json(401, { error: "missing-auth" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json(503, { error: "backend-not-configured" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authData, error: authError } = await userClient.auth.getUser();
  const user = authData.user;
  if (authError || !user) return json(401, { error: "invalid-auth" });

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Build 16 real-money recharge is intentionally owner-QA-only until the
  // public pack economics and storefront rules are approved.
  const { data: roleRow, error: roleError } = await admin
    .from("account_roles")
    .select("role")
    .eq("user_id", user.id)
    .maybeSingle();
  if (roleError) return json(500, { error: "role-lookup-failed" });
  if (String(roleRow?.role ?? "").toLowerCase() !== "owner") {
    return json(403, { error: "recharge-owner-qa-only" });
  }

  const token = randomToken();
  const tokenHash = await sha256(token);
  const expiresAt = new Date(Date.now() + 20 * 60 * 1000).toISOString();

  const { error: sessionError } = await admin.from("coin_recharge_sessions").insert({
    user_id: user.id,
    token_hash: tokenHash,
    expires_at: expiresAt,
  });
  if (sessionError) return json(500, { error: "session-create-failed" });

  const url = `${supabaseUrl}/functions/v1/recharge?session=${encodeURIComponent(token)}`;
  return json(201, { url, expires_at: expiresAt, mode: "owner-qa" });
});
