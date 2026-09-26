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

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: "server_configuration_missing" }, 500);
  }
  if (!paypalClientId || !paypalClientSecret) {
    return json({ error: "paypal_credentials_missing" }, 503);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: "unauthorized" }, 401);

  const { data: roleRow, error: roleError } = await admin
    .from("account_roles")
    .select("role")
    .eq("user_id", userData.user.id)
    .maybeSingle();
  if (roleError) return json({ error: "role_lookup_failed" }, 500);
  if ((roleRow?.role ?? "").toLowerCase() !== "owner") {
    return json({ error: "owner_required" }, 403);
  }

  const payload = await req.json().catch(() => null) as {
    payout_id?: string;
    expected_environment?: string;
  } | null;
  const payoutId = payload?.payout_id?.trim();
  if (!payoutId) return json({ error: "payout_id_required" }, 400);

  const expectedEnvironment = payload?.expected_environment?.trim().toLowerCase();
  if (expectedEnvironment && expectedEnvironment !== paypalEnv) {
    return json({
      error: "paypal_environment_mismatch",
      expected_environment: expectedEnvironment,
      configured_environment: paypalEnv,
    }, 409);
  }

  const { data: beginRows, error: beginError } = await userClient.rpc(
    "begin_creator_payout_processing",
    { p_payout_id: payoutId },
  );
  if (beginError) {
    return json({ error: "payout_not_processable", detail: beginError.message }, 409);
  }
  const payout = Array.isArray(beginRows) ? beginRows[0] : null;
  if (!payout) return json({ error: "payout_not_found" }, 404);
  if (payout.payout_provider !== "paypal") {
    await admin.from("creator_payout_requests").update({
      status: "failed",
      provider_status: "UNSUPPORTED_PROVIDER",
      provider_status_updated_at: new Date().toISOString(),
      moderation_note: "Unsupported payout provider.",
    }).eq("id", payoutId);
    return json({ error: "unsupported_provider" }, 400);
  }

  const baseUrl = paypalEnv === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";

  try {
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
    if (!tokenResponse.ok || !tokenJson.access_token) {
      await admin.from("creator_payout_requests").update({
        status: "failed",
        provider_status: "AUTH_FAILED",
        provider_status_updated_at: new Date().toISOString(),
        moderation_note: "PayPal authentication failed.",
      }).eq("id", payoutId);
      return json({ error: "paypal_auth_failed" }, 502);
    }

    const amount = (Number(payout.amount_cents) / 100).toFixed(2);
    const senderBatchId = `fv-${payoutId}`;
    const payoutResponse = await fetch(`${baseUrl}/v1/payments/payouts`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokenJson.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        sender_batch_header: {
          sender_batch_id: senderBatchId,
          email_subject: "Your Fameverse payout",
          email_message: "Your Fameverse creator payout has been sent.",
        },
        items: [{
          recipient_type: "EMAIL",
          amount: { value: amount, currency: "USD" },
          note: `Fameverse creator payout ${payoutId}`,
          sender_item_id: payoutId,
          receiver: payout.payout_recipient,
        }],
      }),
    });
    const payoutJson = await payoutResponse.json();
    if (!payoutResponse.ok) {
      await admin.from("creator_payout_requests").update({
        status: "failed",
        provider_status: payoutJson?.name ?? `HTTP_${payoutResponse.status}`,
        provider_status_updated_at: new Date().toISOString(),
        moderation_note: payoutJson?.message ?? "PayPal payout submission failed.",
      }).eq("id", payoutId);
      return json({ error: "paypal_payout_failed", detail: payoutJson }, 502);
    }

    const batchId = payoutJson?.batch_header?.payout_batch_id ?? null;
    const batchStatus = payoutJson?.batch_header?.batch_status ?? "PENDING";
    await admin.from("creator_payout_requests").update({
      status: "processing",
      provider_batch_id: batchId,
      provider_status: batchStatus,
      provider_status_updated_at: new Date().toISOString(),
      external_reference: batchId,
    }).eq("id", payoutId);

    return json({
      ok: true,
      payout_id: payoutId,
      provider: "paypal",
      environment: paypalEnv,
      provider_batch_id: batchId,
      provider_status: batchStatus,
    });
  } catch (error) {
    await admin.from("creator_payout_requests").update({
      status: "failed",
      provider_status: "NETWORK_ERROR",
      provider_status_updated_at: new Date().toISOString(),
      moderation_note: error instanceof Error ? error.message : "Unknown payout error",
    }).eq("id", payoutId);
    return json({ error: "payout_network_error" }, 502);
  }
});
