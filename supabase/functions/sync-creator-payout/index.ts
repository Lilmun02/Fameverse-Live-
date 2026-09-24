import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const paypalClientId = Deno.env.get("PAYPAL_CLIENT_ID") ?? "";
  const paypalClientSecret = Deno.env.get("PAYPAL_CLIENT_SECRET") ?? "";
  const paypalEnv = (
    Deno.env.get("PAYPAL_ENV") ?? Deno.env.get("PAYPAL_ENVIRONMENT") ?? "sandbox"
  ).toLowerCase();

  if (!supabaseUrl || !anonKey || !serviceRoleKey) return json({ error: "server_configuration_missing" }, 500);
  if (!paypalClientId || !paypalClientSecret) return json({ error: "paypal_credentials_missing" }, 503);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: "unauthorized" }, 401);

  const { data: roleRow } = await admin
    .from("account_roles")
    .select("role")
    .eq("user_id", userData.user.id)
    .maybeSingle();
  if ((roleRow?.role ?? "").toLowerCase() !== "owner") return json({ error: "owner_required" }, 403);

  const payload = await req.json().catch(() => null) as { payout_id?: string } | null;
  const payoutId = payload?.payout_id?.trim();
  if (!payoutId) return json({ error: "payout_id_required" }, 400);

  const { data: payout, error: payoutError } = await admin
    .from("creator_payout_requests")
    .select("id, status, provider_batch_id, provider_status")
    .eq("id", payoutId)
    .maybeSingle();
  if (payoutError) return json({ error: "payout_lookup_failed" }, 500);
  if (!payout) return json({ error: "payout_not_found" }, 404);
  if (!payout.provider_batch_id) return json({ error: "provider_batch_missing" }, 409);

  const baseUrl = paypalEnv === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";

  const basic = btoa(`${paypalClientId}:${paypalClientSecret}`);
  const tokenResponse = await fetch(`${baseUrl}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  const tokenJson = await tokenResponse.json();
  if (!tokenResponse.ok || !tokenJson.access_token) return json({ error: "paypal_auth_failed" }, 502);

  const statusResponse = await fetch(
    `${baseUrl}/v1/payments/payouts/${payout.provider_batch_id}?page=1&page_size=100&total_required=true`,
    { headers: { Authorization: `Bearer ${tokenJson.access_token}` } },
  );
  const statusJson = await statusResponse.json();
  if (!statusResponse.ok) return json({ error: "paypal_status_failed", detail: statusJson }, 502);

  const batchStatus = String(statusJson?.batch_header?.batch_status ?? "PENDING").toUpperCase();
  const item = Array.isArray(statusJson?.items) ? statusJson.items[0] : null;
  const itemStatus = String(item?.transaction_status ?? batchStatus).toUpperCase();
  const providerItemId = item?.payout_item_id ?? null;

  let fameverseStatus = "processing";
  if (itemStatus === "SUCCESS") {
    fameverseStatus = "paid";
  } else if (["UNCLAIMED", "HELD", "ONHOLD"].includes(itemStatus)) {
    fameverseStatus = "held";
  } else if (["FAILED", "RETURNED", "BLOCKED", "REFUNDED", "DENIED"].includes(itemStatus)) {
    fameverseStatus = "failed";
  }

  const now = new Date().toISOString();
  const { error: providerUpdateError } = await admin
    .from("creator_payout_requests")
    .update({
      provider_item_id: providerItemId,
      provider_status: itemStatus,
      provider_status_updated_at: now,
    })
    .eq("id", payoutId);
  if (providerUpdateError) return json({ error: "provider_status_update_failed" }, 500);

  if (fameverseStatus !== "processing") {
    const { error: reviewError } = await userClient.rpc("review_creator_payout", {
      p_payout_id: payoutId,
      p_status: fameverseStatus,
      p_moderation_note: fameverseStatus === "failed"
        ? `PayPal status: ${itemStatus}`
        : null,
      p_external_reference: payout.provider_batch_id,
    });
    if (reviewError) return json({ error: "fameverse_status_update_failed", detail: reviewError.message }, 500);
  }

  return json({
    ok: true,
    payout_id: payoutId,
    fameverse_status: fameverseStatus,
    provider_status: itemStatus,
    provider_batch_status: batchStatus,
    provider_item_id: providerItemId,
    environment: paypalEnv,
  });
});
