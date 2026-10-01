import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};
const encoder = new TextEncoder();

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function toHex(bytes: Uint8Array) {
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false;
  let diff = 0;
  for (let i = 0; i < left.length; i += 1) {
    diff |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return diff === 0;
}

async function verifyStripeSignature(rawBody: string, header: string, secret: string) {
  const entries = header.split(",").map((part) => part.trim());
  const timestampRaw = entries.find((part) => part.startsWith("t="))?.slice(2) ?? "";
  const signatures = entries
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3))
    .filter(Boolean);
  const timestamp = Number(timestampRaw);
  if (!Number.isFinite(timestamp) || signatures.length === 0) return false;
  if (Math.abs(Math.floor(Date.now() / 1000) - timestamp) > 300) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(`${timestampRaw}.${rawBody}`),
  );
  const expected = toHex(new Uint8Array(digest));
  return signatures.some((signature) => constantTimeEqual(expected, signature));
}

function objectId(value: unknown) {
  if (typeof value === "string") return value;
  if (value && typeof value === "object" && "id" in value) {
    return String((value as Record<string, unknown>).id ?? "");
  }
  return "";
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method-not-allowed" });

  const webhookSecret = (Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "").trim();
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!webhookSecret || !supabaseUrl || !serviceRoleKey) {
    return json(503, { error: "stripe-webhook-not-configured" });
  }

  const signature = req.headers.get("Stripe-Signature") ?? "";
  const rawBody = await req.text();
  if (!signature || !(await verifyStripeSignature(rawBody, signature, webhookSecret))) {
    return json(400, { error: "invalid-stripe-signature" });
  }

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody) as Record<string, unknown>;
  } catch {
    return json(400, { error: "invalid-json" });
  }

  const eventType = String(event.type ?? "");
  const data = event.data as Record<string, unknown> | undefined;
  const stripeObject = data?.object as Record<string, unknown> | undefined;
  if (!stripeObject) return json(200, { received: true, ignored: true });

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (eventType === "checkout.session.expired") {
    const sessionId = String(stripeObject.id ?? "");
    if (sessionId) {
      await admin
        .from("coin_recharge_orders")
        .update({ status: "cancelled", updated_at: new Date().toISOString() })
        .eq("provider", "stripe")
        .eq("provider_order_id", sessionId)
        .eq("status", "created");
    }
    return json(200, { received: true, status: "expired" });
  }

  if (
    eventType !== "checkout.session.completed" &&
    eventType !== "checkout.session.async_payment_succeeded"
  ) {
    return json(200, { received: true, ignored: true });
  }

  if (String(stripeObject.mode ?? "") !== "payment") {
    return json(200, { received: true, ignored: true });
  }
  if (String(stripeObject.payment_status ?? "") !== "paid") {
    return json(200, { received: true, pending: true });
  }

  const metadata = (stripeObject.metadata ?? {}) as Record<string, unknown>;
  const rechargeId = String(metadata.recharge_id ?? "");
  const expectedUserId = String(metadata.user_id ?? "");
  const sessionId = String(stripeObject.id ?? "");
  const paymentIntentId = objectId(stripeObject.payment_intent);
  const amountCents = Number(stripeObject.amount_total);
  const currency = String(stripeObject.currency ?? "").toUpperCase();

  if (
    !rechargeId ||
    !expectedUserId ||
    !sessionId ||
    !paymentIntentId ||
    !Number.isInteger(amountCents) ||
    amountCents <= 0 ||
    !/^[A-Z]{3}$/.test(currency)
  ) {
    return json(400, { error: "invalid-stripe-checkout-payload" });
  }

  const { data: order, error: orderError } = await admin
    .from("coin_recharge_orders")
    .select("id,user_id,provider,provider_order_id,status")
    .eq("id", rechargeId)
    .maybeSingle();
  if (orderError || !order) return json(404, { error: "stripe-recharge-order-not-found" });
  if (order.provider !== "stripe" || order.user_id !== expectedUserId) {
    return json(409, { error: "stripe-recharge-order-mismatch" });
  }
  if (order.provider_order_id && order.provider_order_id !== sessionId) {
    return json(409, { error: "stripe-session-mismatch" });
  }

  const { data: finalized, error: finalizeError } = await admin.rpc(
    "finalize_coin_recharge",
    {
      p_recharge_id: rechargeId,
      p_provider_order_id: sessionId,
      p_provider_capture_id: paymentIntentId,
      p_amount_cents: amountCents,
      p_currency: currency,
    },
  );
  if (finalizeError) return json(500, { error: "stripe-wallet-credit-failed" });

  const result = Array.isArray(finalized) ? finalized[0] : finalized;
  return json(200, {
    received: true,
    status: "completed",
    recharge_id: rechargeId,
    credited_coins: result?.credited_coins ?? null,
    wallet_balance: result?.wallet_balance ?? null,
    already_completed: result?.already_completed ?? false,
  });
});
