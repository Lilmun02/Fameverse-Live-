import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function base64Url(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

async function signUserToken(secret: string, userId: string) {
  const encoder = new TextEncoder();
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "HS256", typ: "JWT" })));
  const payload = base64Url(
    encoder.encode(
      JSON.stringify({ user_id: userId, iat: now - 60, exp: now + 3600 }),
    ),
  );
  const unsigned = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(unsigned));
  return `${unsigned}.${base64Url(new Uint8Array(signature))}`;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return response(405, { error: "method-not-allowed" });

  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return response(401, { error: "missing-auth" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const streamApiKey = Deno.env.get("STREAM_API_KEY") ?? "";
  const streamApiSecret = Deno.env.get("STREAM_API_SECRET") ?? "";

  if (!streamApiKey || !streamApiSecret) {
    return response(503, { error: "stream-not-configured" });
  }

  let payload: { room_id?: string; role?: string };
  try {
    payload = await req.json();
  } catch {
    return response(400, { error: "invalid-json" });
  }

  const roomId = String(payload.room_id ?? "").trim();
  const role = String(payload.role ?? "viewer").trim().toLowerCase();
  if (!roomId || !["host", "viewer"].includes(role)) {
    return response(400, { error: "invalid-request" });
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();
  if (userError || !user) return response(401, { error: "invalid-auth" });

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: room, error: roomError } = await admin
    .from("live_rooms")
    .select("id, host_user_id, status")
    .eq("id", roomId)
    .maybeSingle();

  if (roomError) return response(500, { error: "room-lookup-failed" });
  if (!room) return response(404, { error: "room-not-found" });
  if (room.status !== "live") return response(409, { error: "room-not-live" });

  const isHost = room.host_user_id === user.id;
  if (role === "host" && !isHost) {
    return response(403, { error: "host-role-forbidden" });
  }

  const callId = `fv_${room.id}`;
  const userToken = await signUserToken(streamApiSecret, user.id);

  return response(201, {
    api_key: streamApiKey,
    user_token: userToken,
    user_id: user.id,
    call_id: callId,
    role,
  });
});
