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

function stripeEnvironment() {
  return (Deno.env.get("STRIPE_ENVIRONMENT") ?? "test").trim().toLowerCase() === "live"
    ? "live"
    : "test";
}

function secretForEnvironment(environment: string) {
  const named = environment === "live"
    ? Deno.env.get("STRIPE_LIVE_SECRET_KEY")
    : Deno.env.get("STRIPE_TEST_SECRET_KEY");
  return (named ?? Deno.env.get("STRIPE_SECRET_KEY") ?? "").trim();
}

function validSecretForEnvironment(secret: string, environment: string) {
  if (environment === "live") return secret.startsWith("sk_live_");
  return secret.startsWith("sk_test_");
}

type StripePack = {
  id: string;
  label: string;
  coins: number;
  price_cents: number;
  currency: string;
  stripe_test_price_id: string | null;
  stripe_live_price_id: string | null;
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
  const secretKey = secretForEnvironment(environment);

  const packQuery = admin
    .from("coin_recharge_packs")
    .select(
      "id,label,coins,price_cents,currency,stripe_test_price_id,stripe_live_price_id",
    )
    .eq("active", true)
    .eq("owner_only", false)
    .like("id", "stripe-%")
    .order("sort_order", { ascending: true });

  if (action === "config") {
    const { data: packs, error: packError } = await packQuery;
    if (packError) return json(500, { error: "stripe-pack-load-failed" });

    const visible = (packs ?? []).map((raw) => {
      const pack = raw as StripePack;
      return {
        id: pack.id,
        label: pack.label,
        coins: pack.coins,
        price_cents: pack.price_cents,
        currency: pack.currency,
      };
    });

    return json(200, {
      provider: "stripe",
      checkout: "hosted",
      environment,
      checkout_enabled:
        Boolean(secretKey) && validSecretForEnvironment(secretKey, environment),
      packs: visible,
    });
  }

  if (action !== "create") return json(400, { error: "unknown-action" });
  if (!secretKey || !validSecretForEnvironment(secretKey, environment)) {
    return json(503, { error: "stripe-not-configured", environment });
  }

  const packId = String(body.pack_id ?? "");
  if (!packId.startsWith("stripe-")) return json(400, { error: "invalid-stripe-pack" });

  const { data: rawPack, error: packError } = await admin
    .from("coin_recharge_packs")
    .select(
      "id,label,coins,price_cents,currency,stripe_test_price_id,stripe_live_price_id",
    )
    .eq("id", packId)
    .eq("active", true)
    .eq("owner_only", false)
    .maybeSingle();
  if (packError || !rawPack) return json(404, { error: "stripe-pack-not-found" });

  const pack = rawPack as StripePack;
  const stripePriceId = environment === "live"
    ? String(pack.stripe_live_price_id ?? "")
    : String(pack.stripe_test_price_id ?? "");
  if (!stripePriceId.startsWith("price_")) {
    return json(503, { error: "stripe-price-not-configured", environment });
  }

  const { data: recharge, error: rechargeError } = await admin
    .from("coin_recharge_orders")
    .insert({
      user_id: user.id,
      pack_id: pack.id,
      provider: "stripe",
      amount_cents: pack.price_cents,
      currency: pack.currency,
      coins: pack.coins,
      status: "created",
    })
    .select("id")
    .single();
  if (rechargeError || !recharge) return json(500, { error: "stripe-order-create-failed" });

  const returnBase = `${supabaseUrl}/functions/v1/stripe-return`;
  const form = new URLSearchParams();
  form.set("mode", "payment");
  form.set("ui_mode", "hosted_page");
  form.set("origin_context", "mobile_app");
  form.set("payment_method_types[0]", "card");
  form.set("line_items[0][price]", stripePriceId);
  form.set("line_items[0][quantity]", "1");
  form.set("client_reference_id", user.id);
  form.set("success_url", `${returnBase}?status=success&session_id={CHECKOUT_SESSION_ID}`);
  form.set("cancel_url", `${returnBase}?status=cancelled`);
  form.set("expires_at", String(Math.floor(Date.now() / 1000) + 30 * 60));
  form.set("submit_type", "pay");
  form.set("locale", "auto");
  form.set("metadata[recharge_id]", recharge.id);
  form.set("metadata[user_id]", user.id);
  form.set("metadata[pack_id]", pack.id);
  form.set("metadata[coins]", String(pack.coins));
  form.set("payment_intent_data[metadata][recharge_id]", recharge.id);
  form.set("payment_intent_data[metadata][user_id]", user.id);
  form.set("payment_intent_data[metadata][pack_id]", pack.id);
  if (user.email) form.set("customer_email", user.email);

  try {
    const stripeResponse = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${secretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "Idempotency-Key": `fv-stripe-checkout-${recharge.id}`,
      },
      body: form.toString(),
    });
    const session = await stripeResponse.json();
    const sessionId = String(session?.id ?? "");
    const checkoutUrl = String(session?.url ?? "");
    if (!stripeResponse.ok || !sessionId || !checkoutUrl) {
      await admin
        .from("coin_recharge_orders")
        .update({ status: "failed", updated_at: new Date().toISOString() })
        .eq("id", recharge.id);
      return json(502, { error: "stripe-checkout-create-failed" });
    }

    await admin
      .from("coin_recharge_orders")
      .update({ provider_order_id: sessionId, updated_at: new Date().toISOString() })
      .eq("id", recharge.id);

    return json(201, {
      provider: "stripe",
      checkout: "hosted",
      environment,
      order_id: recharge.id,
      checkout_session_id: sessionId,
      checkout_url: checkoutUrl,
      coins: pack.coins,
      amount_cents: pack.price_cents,
      currency: pack.currency,
    });
  } catch {
    await admin
      .from("coin_recharge_orders")
      .update({ status: "failed", updated_at: new Date().toISOString() })
      .eq("id", recharge.id);
    return json(502, { error: "stripe-checkout-create-failed" });
  }
});
