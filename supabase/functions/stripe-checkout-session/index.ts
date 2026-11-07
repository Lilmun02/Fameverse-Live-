import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, authorization, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};
const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" };

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function stripeEnvironment(): "live" | "test" | null {
  const configured = (Deno.env.get("STRIPE_ENVIRONMENT") ?? "").trim().toLowerCase();
  return configured === "live" || configured === "test" ? configured : null;
}

function secretForEnvironment(environment: "live" | "test") {
  const named = environment === "live"
    ? Deno.env.get("STRIPE_LIVE_SECRET_KEY")
    : Deno.env.get("STRIPE_TEST_SECRET_KEY");
  return (named ?? "").trim();
}

function validSecretForEnvironment(secret: string, environment: "live" | "test") {
  if (environment === "live") return secret.startsWith("sk_live_") || secret.startsWith("rk_live_");
  return secret.startsWith("sk_test_") || secret.startsWith("rk_test_");
}

type StripePack = {
  id: string;
  label: string;
  coins: number;
  currency: string;
  stripe_test_price_id: string | null;
  stripe_live_price_id: string | null;
  stripe_test_price_cents: number | null;
  stripe_live_price_cents: number | null;
};

const BLACK_FRIDAY_END_AT = Date.parse("2026-12-07T20:56:27.556Z");
const BLACK_FRIDAY_PACK_IDS = new Set(["stripe-bf2026-10000", "stripe-bf2026-50000", "stripe-bf2026-100000"]);
function isExpiredBlackFridayPack(id: string): boolean {
  return BLACK_FRIDAY_PACK_IDS.has(id) && Date.now() >= BLACK_FRIDAY_END_AT;
}

function priceForEnvironment(pack: StripePack, environment: "live" | "test"): number | null {
  const amount = environment === "live"
    ? pack.stripe_live_price_cents
    : pack.stripe_test_price_cents;
  return Number.isInteger(amount) && Number(amount) > 0 ? Number(amount) : null;
}

type Claim = {
  order_id: string;
  claim_token: string | null;
  provider_order_id: string | null;
  claim_status: "claimed" | "busy" | "existing" | "mismatch";
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method-not-allowed" });

  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return json(401, { error: "missing-auth" });

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

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid-json" });
  }

  const action = String(body.action ?? "config");
  const environment = stripeEnvironment();
  const packColumns =
    "id,label,coins,currency,stripe_test_price_id,stripe_live_price_id,stripe_test_price_cents,stripe_live_price_cents";

  if (!environment) {
    if (action === "config") {
      return json(200, {
        provider: "stripe",
        checkout: "hosted",
        environment: null,
        checkout_enabled: false,
        packs: [],
        configuration_error: "stripe-environment-not-configured",
      });
    }
    return json(503, { error: "stripe-environment-not-configured" });
  }

  const secretKey = secretForEnvironment(environment);
  const secretValid = Boolean(secretKey) && validSecretForEnvironment(secretKey, environment);
  const packQuery = admin
    .from("coin_recharge_packs")
    .select(packColumns)
    .eq("active", true)
    .eq("owner_only", false)
    .like("id", "stripe-%")
    .order("sort_order", { ascending: true });

  if (action === "config") {
    const { data: packs, error: packError } = await packQuery;
    if (packError) return json(500, { error: "stripe-pack-load-failed" });

    const visible = (packs ?? []).filter((raw) => !isExpiredBlackFridayPack(String(raw.id ?? ""))).map((raw) => {
      const pack = raw as StripePack;
      return {
        id: pack.id,
        label: pack.label,
        coins: pack.coins,
        price_cents: priceForEnvironment(pack, environment),
        currency: pack.currency,
      };
    });

    return json(200, {
      provider: "stripe",
      checkout: "hosted",
      environment,
      checkout_enabled: secretValid && visible.every((pack) => Number.isInteger(pack.price_cents) && Number(pack.price_cents) > 0),
      packs: visible,
    });
  }

  if (action !== "create") return json(400, { error: "unknown-action" });
  if (!secretValid) return json(503, { error: "stripe-not-configured", environment });

  const packId = String(body.pack_id ?? "");
  if (!packId.startsWith("stripe-")) return json(400, { error: "invalid-stripe-pack" });
  if (isExpiredBlackFridayPack(packId)) return json(410, { error: "black-friday-sale-ended" });

  const { data: rawPack, error: packError } = await admin
    .from("coin_recharge_packs")
    .select(packColumns)
    .eq("id", packId)
    .eq("active", true)
    .eq("owner_only", false)
    .maybeSingle();
  if (packError || !rawPack) return json(404, { error: "stripe-pack-not-found" });

  const pack = rawPack as StripePack;
  const priceCents = priceForEnvironment(pack, environment);
  if (!priceCents) return json(503, { error: "stripe-price-amount-not-configured", environment });

  const currency = String(pack.currency ?? "").toLowerCase();
  if (!/^[a-z]{3}$/.test(currency)) return json(503, { error: "stripe-currency-not-configured" });

  async function claimOrder(): Promise<{ claim: Claim | null; error: unknown }> {
    const result = await admin.rpc("claim_stripe_checkout_order", {
      p_user_id: user.id,
      p_pack_id: pack.id,
      p_environment: environment,
      p_amount_cents: priceCents,
      p_currency: pack.currency,
      p_coins: pack.coins,
    });
    const rows = result.data as Claim[] | null;
    return { claim: rows?.[0] ?? null, error: result.error };
  }

  let claimed = await claimOrder();
  if (claimed.error || !claimed.claim) {
    console.error("Stripe checkout claim failed", claimed.error);
    return json(503, { error: "stripe-checkout-claim-failed" });
  }

  let claim = claimed.claim;
  if (claim.claim_status === "busy") {
    return json(409, { error: "checkout-session-in-progress", retry_after_seconds: 30 });
  }
  if (claim.claim_status === "mismatch") {
    return json(409, { error: "existing-checkout-order-requires-reconciliation" });
  }

  if (claim.claim_status === "existing" && claim.provider_order_id) {
    const existingResponse = await fetch(
      `https://api.stripe.com/v1/checkout/sessions/${encodeURIComponent(claim.provider_order_id)}`,
      { headers: { Authorization: `Bearer ${secretKey}` } },
    );
    const existingSession = await existingResponse.json();
    if (!existingResponse.ok) {
      console.error("Existing Stripe Checkout Session lookup failed", {
        status: existingResponse.status,
        code: existingSession?.error?.code,
      });
      return json(502, { error: "existing-checkout-session-lookup-failed" });
    }

    if (existingSession?.status === "open" && existingSession?.url) {
      return json(200, {
        provider: "stripe",
        checkout: "hosted",
        environment,
        order_id: claim.order_id,
        checkout_session_id: claim.provider_order_id,
        checkout_url: String(existingSession.url),
        coins: pack.coins,
        amount_cents: priceCents,
        currency: pack.currency,
        reused: true,
      });
    }

    if (existingSession?.status === "expired") {
      const { data: cancelled, error: cancelError } = await admin
        .from("coin_recharge_orders")
        .update({ status: "cancelled", updated_at: new Date().toISOString() })
        .eq("id", claim.order_id)
        .eq("provider_order_id", claim.provider_order_id)
        .eq("status", "created")
        .select("id")
        .maybeSingle();
      if (cancelError || !cancelled) {
        return json(409, { error: "expired-checkout-reconciliation-required" });
      }
      claimed = await claimOrder();
      if (claimed.error || !claimed.claim) {
        return json(503, { error: "stripe-checkout-claim-failed" });
      }
      claim = claimed.claim;
      if (claim.claim_status === "busy") {
        return json(409, { error: "checkout-session-in-progress", retry_after_seconds: 30 });
      }
      if (claim.claim_status === "mismatch" || claim.claim_status === "existing") {
        return json(409, { error: "checkout-order-reconciliation-required" });
      }
    } else {
      return json(409, { error: "checkout-payment-already-processing" });
    }
  }

  if (claim.claim_status !== "claimed" || !claim.claim_token) {
    return json(409, { error: "checkout-claim-not-owned" });
  }

  const returnBase = `${supabaseUrl}/functions/v1/stripe-return`;
  const form = new URLSearchParams();
  form.set("mode", "payment");
  form.set("ui_mode", "hosted_page");
  const webCheckout = body.origin_context === "web";
  form.set("managed_payments[enabled]", "false");
  form.set("line_items[0][price_data][currency]", currency);
  form.set("line_items[0][price_data][unit_amount]", String(priceCents));
  form.set("line_items[0][price_data][product_data][name]", pack.label);
  form.set("line_items[0][quantity]", "1");
  form.set("client_reference_id", user.id);
  const successUrl = webCheckout
    ? "https://fameverse.app/coins?checkout=success&session_id={CHECKOUT_SESSION_ID}"
    : `${returnBase}?status=success&session_id={CHECKOUT_SESSION_ID}`;
  const cancelUrl = webCheckout
    ? "https://fameverse.app/coins?checkout=cancelled"
    : `${returnBase}?status=cancelled`;
  form.set("success_url", successUrl);
  form.set("cancel_url", cancelUrl);
  form.set("submit_type", "pay");
  form.set("locale", "auto");
  form.set("metadata[recharge_id]", claim.order_id);
  form.set("metadata[user_id]", user.id);
  form.set("metadata[pack_id]", pack.id);
  form.set("metadata[coins]", String(pack.coins));
  form.set("payment_intent_data[metadata][recharge_id]", claim.order_id);
  form.set("payment_intent_data[metadata][user_id]", user.id);
  form.set("payment_intent_data[metadata][pack_id]", pack.id);
  if (user.email) form.set("customer_email", user.email);

  try {
    const stripeResponse = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "Idempotency-Key": `fv-stripe-checkout-${claim.order_id}`,
      },
      body: form.toString(),
    });
    const session = await stripeResponse.json();
    const sessionId = String(session?.id ?? "");
    const checkoutUrl = String(session?.url ?? "");
    if (!stripeResponse.ok || !sessionId || !checkoutUrl) {
      console.error("Stripe Checkout Session creation failed", {
        status: stripeResponse.status,
        type: session?.error?.type,
        code: session?.error?.code,
        param: session?.error?.param,
        message: String(session?.error?.message ?? "").slice(0, 400),
        request_id: stripeResponse.headers.get("request-id"),
      });
      return json(502, { error: "stripe-checkout-create-failed" });
    }

    const { data: saved, error: saveError } = await admin
      .from("coin_recharge_orders")
      .update({
        provider_order_id: sessionId,
        checkout_claim_token: null,
        checkout_lease_until: null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", claim.order_id)
      .eq("checkout_claim_token", claim.claim_token)
      .is("provider_order_id", null)
      .eq("status", "created")
      .select("id")
      .maybeSingle();

    if (saveError || !saved) {
      console.error("Stripe Checkout Session persistence did not confirm ownership", {
        order_id: claim.order_id,
        error: saveError,
      });
      return json(503, { error: "checkout-session-persistence-pending" });
    }

    return json(201, {
      provider: "stripe",
      checkout: "hosted",
      environment,
      order_id: claim.order_id,
      checkout_session_id: sessionId,
      checkout_url: checkoutUrl,
      coins: pack.coins,
      amount_cents: priceCents,
      currency: pack.currency,
    });
  } catch (error) {
    console.error("Stripe Checkout Session request outcome is uncertain", {
      order_id: claim.order_id,
      error: String(error),
    });
    return json(502, { error: "stripe-checkout-create-outcome-unknown" });
  }
});
