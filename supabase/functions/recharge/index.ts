import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Native Fameverse recharge is API-only: Supabase validates the owner QA
// session and talks directly to PayPal. Vercel/HTML checkout is never part of
// the payment path.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, authorization, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json; charset=utf-8",
};

const CUSTOM_PACK_ID = "owner-qa-custom";
const CUSTOM_MIN_COINS = 100;
const CUSTOM_MAX_COINS = 10000;
const CUSTOM_CENTS_PER_COIN = 1;

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function hex(bytes: Uint8Array) {
  return [...bytes]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return hex(new Uint8Array(digest));
}

function paypalBase(environment: string) {
  return environment === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}

async function paypalAccessToken(
  clientId: string,
  secret: string,
  environment: string,
) {
  const response = await fetch(`${paypalBase(environment)}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${clientId}:${secret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!response.ok) throw new Error("paypal-auth-failed");
  const data = await response.json();
  const token = String(data.access_token ?? "");
  if (!token) throw new Error("paypal-auth-failed");
  return token;
}

async function sessionContext(
  admin: ReturnType<typeof createClient>,
  token: string,
) {
  if (!token) return null;
  const tokenHash = await sha256(token);
  const { data, error } = await admin
    .from("coin_recharge_sessions")
    .select("id,user_id,expires_at,revoked_at")
    .eq("token_hash", tokenHash)
    .maybeSingle();

  if (error || !data || data.revoked_at) return null;
  if (new Date(data.expires_at).getTime() <= Date.now()) return null;

  await admin
    .from("coin_recharge_sessions")
    .update({ last_used_at: new Date().toISOString() })
    .eq("id", data.id);

  return data;
}

async function requireOwner(
  admin: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data } = await admin
    .from("account_roles")
    .select("role")
    .eq("user_id", userId)
    .maybeSingle();
  return String(data?.role ?? "").toLowerCase() === "owner";
}

async function activeOwnerPacks(admin: ReturnType<typeof createClient>) {
  return admin
    .from("coin_recharge_packs")
    .select("id,label,coins,price_cents,currency,owner_only")
    .eq("active", true)
    .eq("owner_only", true)
    .neq("id", CUSTOM_PACK_ID)
    .order("sort_order", { ascending: true })
    .order("price_cents", { ascending: true });
}

type RechargePack = {
  id: string;
  label: string;
  coins: number;
  price_cents: number;
  currency: string;
  active: boolean;
  owner_only: boolean;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json(405, {
      error: "native-checkout-required",
      message: "Fameverse recharge is handled in the native app.",
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const paypalClientId = Deno.env.get("PAYPAL_CLIENT_ID") ?? "";
  const paypalSecret = Deno.env.get("PAYPAL_CLIENT_SECRET") ?? "";
  const paypalEnvironment =
    (Deno.env.get("PAYPAL_ENVIRONMENT") ?? "sandbox").toLowerCase() === "live"
      ? "live"
      : "sandbox";

  if (!supabaseUrl || !serviceRoleKey) {
    return json(503, { error: "backend-not-configured" });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const requestUrl = new URL(req.url);
  let sessionToken = requestUrl.searchParams.get("session") ?? "";

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid-json" });
  }

  sessionToken = String(body.session ?? sessionToken);
  const session = await sessionContext(admin, sessionToken);
  if (!session) {
    return json(401, { error: "invalid-or-expired-recharge-session" });
  }
  if (!(await requireOwner(admin, session.user_id))) {
    return json(403, { error: "recharge-owner-qa-only" });
  }

  const action = String(body.action ?? "");

  if (action === "config") {
    const { data: packs, error: packError } = await activeOwnerPacks(admin);
    if (packError) {
      return json(500, { error: "recharge-pack-load-failed" });
    }
    if (!paypalClientId || !paypalSecret) {
      return json(503, { error: "paypal-not-configured" });
    }
    return json(200, {
      environment: paypalEnvironment,
      packs: packs ?? [],
      custom: {
        enabled: true,
        pack_id: CUSTOM_PACK_ID,
        min_coins: CUSTOM_MIN_COINS,
        max_coins: CUSTOM_MAX_COINS,
        cents_per_coin: CUSTOM_CENTS_PER_COIN,
      },
      checkout: "native",
    });
  }

  if (!paypalClientId || !paypalSecret) {
    return json(503, { error: "paypal-not-configured" });
  }

  if (action === "create") {
    const packId = String(body.pack_id ?? "");
    let pack: RechargePack | null = null;

    if (packId === CUSTOM_PACK_ID) {
      const customCoins = Number(body.custom_coins);
      if (
        !Number.isInteger(customCoins) ||
        customCoins < CUSTOM_MIN_COINS ||
        customCoins > CUSTOM_MAX_COINS
      ) {
        return json(400, {
          error: "invalid-custom-coin-amount",
          min_coins: CUSTOM_MIN_COINS,
          max_coins: CUSTOM_MAX_COINS,
        });
      }

      const { data: customPack, error: customPackError } = await admin
        .from("coin_recharge_packs")
        .select("id,label,currency,active,owner_only")
        .eq("id", CUSTOM_PACK_ID)
        .eq("active", true)
        .maybeSingle();

      if (customPackError || !customPack || !customPack.owner_only) {
        return json(404, { error: "custom-recharge-not-available" });
      }

      pack = {
        id: CUSTOM_PACK_ID,
        label: "Custom Fame Coins",
        coins: customCoins,
        price_cents: customCoins * CUSTOM_CENTS_PER_COIN,
        currency: String(customPack.currency ?? "USD"),
        active: true,
        owner_only: true,
      };
    } else {
      const { data: fixedPack, error: packError } = await admin
        .from("coin_recharge_packs")
        .select("id,label,coins,price_cents,currency,active,owner_only")
        .eq("id", packId)
        .eq("active", true)
        .maybeSingle();

      if (packError || !fixedPack) {
        return json(404, { error: "recharge-pack-not-found" });
      }
      if (!fixedPack.owner_only) {
        return json(403, { error: "qa-pack-required" });
      }
      pack = fixedPack as RechargePack;
    }

    const { data: recharge, error: rechargeError } = await admin
      .from("coin_recharge_orders")
      .insert({
        user_id: session.user_id,
        pack_id: pack.id,
        provider: "paypal",
        amount_cents: pack.price_cents,
        currency: pack.currency,
        coins: pack.coins,
        status: "created",
      })
      .select("id")
      .single();

    if (rechargeError || !recharge) {
      return json(500, { error: "recharge-order-create-failed" });
    }

    try {
      const accessToken = await paypalAccessToken(
        paypalClientId,
        paypalSecret,
        paypalEnvironment,
      );
      const requestId = `fv-recharge-${recharge.id}`;
      const value = (Number(pack.price_cents) / 100).toFixed(2);
      const paypalResponse = await fetch(
        `${paypalBase(paypalEnvironment)}/v2/checkout/orders`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            "PayPal-Request-Id": requestId,
          },
          body: JSON.stringify({
            intent: "CAPTURE",
            purchase_units: [
              {
                reference_id: recharge.id,
                custom_id: recharge.id,
                description: `${pack.label} — ${pack.coins} Fame Coins`,
                amount: {
                  currency_code: pack.currency,
                  value,
                },
              },
            ],
          }),
        },
      );
      const paypalOrder = await paypalResponse.json();
      const approvalLink = Array.isArray(paypalOrder.links)
        ? paypalOrder.links.find((link: Record<string, unknown>) => {
            const rel = String(link?.rel ?? "");
            return rel === "approve" || rel === "payer-action";
          })
        : null;
      const approvalUrl = String(approvalLink?.href ?? "");

      if (!paypalResponse.ok || !paypalOrder.id || !approvalUrl) {
        await admin
          .from("coin_recharge_orders")
          .update({ status: "failed", updated_at: new Date().toISOString() })
          .eq("id", recharge.id);
        return json(502, { error: "paypal-order-create-failed" });
      }

      await admin
        .from("coin_recharge_orders")
        .update({
          provider_order_id: paypalOrder.id,
          updated_at: new Date().toISOString(),
        })
        .eq("id", recharge.id);

      return json(201, {
        order_id: paypalOrder.id,
        approval_url: approvalUrl,
        environment: paypalEnvironment,
        coins: pack.coins,
        amount_cents: pack.price_cents,
      });
    } catch {
      await admin
        .from("coin_recharge_orders")
        .update({ status: "failed", updated_at: new Date().toISOString() })
        .eq("id", recharge.id);
      return json(502, { error: "paypal-order-create-failed" });
    }
  }

  if (action === "capture") {
    const orderId = String(body.order_id ?? "");
    if (!orderId) {
      return json(400, { error: "missing-paypal-order-id" });
    }

    const { data: recharge, error: lookupError } = await admin
      .from("coin_recharge_orders")
      .select("id,user_id,amount_cents,currency,coins,status,provider_order_id")
      .eq("provider_order_id", orderId)
      .eq("user_id", session.user_id)
      .maybeSingle();

    if (lookupError || !recharge) {
      return json(404, { error: "recharge-order-not-found" });
    }

    if (recharge.status === "completed") {
      const { data: wallet } = await admin
        .from("beta_coin_wallets")
        .select("balance")
        .eq("user_id", session.user_id)
        .maybeSingle();
      return json(200, {
        status: "completed",
        wallet_balance: wallet?.balance ?? 0,
        credited_coins: recharge.coins,
        already_completed: true,
      });
    }

    try {
      const accessToken = await paypalAccessToken(
        paypalClientId,
        paypalSecret,
        paypalEnvironment,
      );
      const captureResponse = await fetch(
        `${paypalBase(paypalEnvironment)}/v2/checkout/orders/${encodeURIComponent(orderId)}/capture`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            "PayPal-Request-Id": `fv-capture-${recharge.id}`,
          },
          body: "{}",
        },
      );
      const captured = await captureResponse.json();

      if (!captureResponse.ok || captured.status !== "COMPLETED") {
        return json(502, { error: "paypal-capture-not-completed" });
      }

      const capture = captured.purchase_units?.[0]?.payments?.captures?.[0];
      const captureId = String(capture?.id ?? "");
      const amountValue = Number(capture?.amount?.value ?? Number.NaN);
      const amountCents = Math.round(amountValue * 100);
      const currency = String(capture?.amount?.currency_code ?? "");

      if (
        !captureId ||
        amountCents !== Number(recharge.amount_cents) ||
        currency !== recharge.currency
      ) {
        return json(409, { error: "paypal-capture-mismatch" });
      }

      const { data: finalized, error: finalizeError } = await admin.rpc(
        "finalize_coin_recharge",
        {
          p_recharge_id: recharge.id,
          p_provider_order_id: orderId,
          p_provider_capture_id: captureId,
          p_amount_cents: amountCents,
          p_currency: currency,
        },
      );

      if (finalizeError) {
        return json(500, { error: "wallet-credit-failed" });
      }

      const result = Array.isArray(finalized) ? finalized[0] : finalized;
      await admin
        .from("coin_recharge_sessions")
        .update({ revoked_at: new Date().toISOString() })
        .eq("id", session.id);

      return json(200, {
        status: "completed",
        credited_coins: result?.credited_coins ?? recharge.coins,
        wallet_balance: result?.wallet_balance ?? null,
        capture_id: captureId,
      });
    } catch {
      return json(502, { error: "paypal-capture-failed" });
    }
  }

  return json(400, { error: "unknown-action" });
});
