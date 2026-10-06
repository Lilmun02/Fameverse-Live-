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

function payoutBatchIdFromLinks(value: unknown): string | null {
  if (typeof value === "string") {
    const match = value.match(/\/v1\/payments\/payouts\/([^/?#]+)/i);
    return match?.[1] ?? null;
  }
  if (Array.isArray(value)) {
    for (const nested of value) {
      const batchId = payoutBatchIdFromLinks(nested);
      if (batchId) return batchId;
    }
    return null;
  }
  if (value && typeof value === "object") {
    for (const nested of Object.values(value as Record<string, unknown>)) {
      const batchId = payoutBatchIdFromLinks(nested);
      if (batchId) return batchId;
    }
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const legacyPaypalClientId = Deno.env.get("PAYPAL_CLIENT_ID") ?? "";
  const legacyPaypalClientSecret = Deno.env.get("PAYPAL_CLIENT_SECRET") ?? "";
  const legacyPaypalEnv = (
    Deno.env.get("PAYPAL_ENV") ?? Deno.env.get("PAYPAL_ENVIRONMENT") ?? "sandbox"
  ).toLowerCase();

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: "server_configuration_missing" }, 500);
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

  const { data: payoutMeta, error: payoutMetaError } = await admin
    .from("creator_payout_requests")
    .select("payout_environment, is_qa")
    .eq("id", payoutId)
    .maybeSingle();
  if (payoutMetaError) return json({ error: "payout_lookup_failed" }, 500);
  if (!payoutMeta) return json({ error: "payout_not_found" }, 404);

  const requestEnvironment = String(
    payoutMeta.payout_environment ?? "live",
  ).toLowerCase();
  if (!["sandbox", "live"].includes(requestEnvironment)) {
    return json({ error: "invalid_payout_environment" }, 409);
  }
  if (expectedEnvironment && expectedEnvironment !== requestEnvironment) {
    return json({
      error: "payout_environment_mismatch",
      expected_environment: expectedEnvironment,
      request_environment: requestEnvironment,
    }, 409);
  }
  const paypalClientId = requestEnvironment === "live"
    ? (
      Deno.env.get("PAYPAL_LIVE_CLIENT_ID") ??
      (legacyPaypalEnv === "live" ? legacyPaypalClientId : "")
    )
    : (
      Deno.env.get("PAYPAL_SANDBOX_CLIENT_ID") ??
      (legacyPaypalEnv === "sandbox" ? legacyPaypalClientId : "")
    );
  const paypalClientSecret = requestEnvironment === "live"
    ? (
      Deno.env.get("PAYPAL_LIVE_CLIENT_SECRET") ??
      (legacyPaypalEnv === "live" ? legacyPaypalClientSecret : "")
    )
    : (
      Deno.env.get("PAYPAL_SANDBOX_CLIENT_SECRET") ??
      (legacyPaypalEnv === "sandbox" ? legacyPaypalClientSecret : "")
    );
  if (!paypalClientId || !paypalClientSecret) {
    return json({
      error: "paypal_credentials_missing",
      environment: requestEnvironment,
    }, 503);
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

  const baseUrl = requestEnvironment === "live"
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
        moderation_note: "PayPal authentication failed before payout submission.",
      }).eq("id", payoutId);
      return json({ error: "paypal_auth_failed" }, 502);
    }

    const amount = (Number(payout.amount_cents) / 100).toFixed(2);
    const senderBatchId = `fv-${payoutId}`;
    const requestBody = JSON.stringify({
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
    });

    const submit = () => fetch(`${baseUrl}/v1/payments/payouts`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokenJson.access_token}`,
        "Content-Type": "application/json",
        "PayPal-Request-Id": senderBatchId,
      },
      body: requestBody,
    });

    let payoutResponse: Response;
    try {
      payoutResponse = await submit();
    } catch (_) {
      // sender_batch_id and PayPal-Request-Id make the retry idempotent.
      payoutResponse = await submit();
    }

    // PayPal documents that a 5xx can be retried with the same sender_batch_id.
    if (payoutResponse.status >= 500) {
      payoutResponse = await submit();
    }

    const payoutJson = await payoutResponse.json().catch(() => ({}));
    let batchId = payoutJson?.batch_header?.payout_batch_id ?? null;
    let batchStatus = payoutJson?.batch_header?.batch_status ?? "PENDING";

    if (!payoutResponse.ok) {
      const providerErrorName = typeof payoutJson?.name === "string"
        ? payoutJson.name.toUpperCase()
        : "";
      const duplicateBatchId = payoutBatchIdFromLinks(payoutJson);
      if (duplicateBatchId) {
        batchId = duplicateBatchId;
        batchStatus = "PENDING";
      } else if (
        providerErrorName === "DUPLICATE_BATCH_ID" || payoutResponse.status >= 500
      ) {
        // Duplicate and 5xx responses can mean PayPal already accepted this
        // deterministic batch. Never release the reserved creator balance.
        await admin.from("creator_payout_requests").update({
          status: "processing",
          provider_status: "SUBMISSION_UNKNOWN",
          provider_status_updated_at: new Date().toISOString(),
          moderation_note: providerErrorName === "DUPLICATE_BATCH_ID"
            ? "PayPal reported a duplicate deterministic batch without a recoverable batch ID. Keep payout reserved and recover through the idempotent provider flow."
            : "PayPal submission result is unknown. Keep payout reserved and investigate before retrying outside the idempotent provider flow.",
        }).eq("id", payoutId);
        return json({ error: "paypal_submission_unknown" }, 502);
      } else {
        await admin.from("creator_payout_requests").update({
          status: "failed",
          provider_status: payoutJson?.name ?? `HTTP_${payoutResponse.status}`,
          provider_status_updated_at: new Date().toISOString(),
          moderation_note: payoutJson?.message ?? "PayPal rejected the payout submission.",
        }).eq("id", payoutId);
        return json({ error: "paypal_payout_failed", detail: payoutJson }, 502);
      }
    }

    if (!batchId) {
      await admin.from("creator_payout_requests").update({
        status: "processing",
        provider_status: "SUBMISSION_UNKNOWN",
        provider_status_updated_at: new Date().toISOString(),
        moderation_note: "PayPal accepted or returned the submission without a usable batch ID. Keep payout reserved for recovery.",
      }).eq("id", payoutId);
      return json({ error: "paypal_batch_id_missing" }, 502);
    }

    await admin.from("creator_payout_requests").update({
      status: "processing",
      provider_batch_id: batchId,
      provider_status: batchStatus,
      provider_status_updated_at: new Date().toISOString(),
      external_reference: batchId,
      moderation_note: null,
    }).eq("id", payoutId);

    return json({
      ok: true,
      payout_id: payoutId,
      provider: "paypal",
      environment: requestEnvironment,
      is_qa: payoutMeta.is_qa === true,
      provider_batch_id: batchId,
      provider_status: batchStatus,
    });
  } catch (error) {
    // Network ambiguity after begin_processing must not release the reservation:
    // PayPal may have accepted the deterministic batch even if our response was lost.
    await admin.from("creator_payout_requests").update({
      status: "processing",
      provider_status: "SUBMISSION_UNKNOWN",
      provider_status_updated_at: new Date().toISOString(),
      moderation_note: error instanceof Error
        ? `PayPal submission result unknown: ${error.message}`
        : "PayPal submission result unknown.",
    }).eq("id", payoutId);
    return json({ error: "payout_network_unknown" }, 502);
  }
});
