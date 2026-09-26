import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function html(status: number, body: string) {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "X-Frame-Options": "DENY",
      "Content-Security-Policy": "default-src 'self' https://www.paypal.com https://www.paypalobjects.com; script-src 'self' 'unsafe-inline' https://www.paypal.com https://www.paypalobjects.com; connect-src 'self' https://www.paypal.com https://www.paypalobjects.com; img-src 'self' data: https://www.paypalobjects.com https://www.paypal.com; style-src 'self' 'unsafe-inline'; frame-src https://www.paypal.com;",
    },
  });
}

function hex(bytes: Uint8Array) {
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return hex(new Uint8Array(digest));
}

function paypalBase(environment: string) {
  return environment === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}

async function paypalAccessToken(clientId: string, secret: string, environment: string) {
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

async function sessionContext(admin: ReturnType<typeof createClient>, token: string) {
  if (!token) return null;
  const tokenHash = await sha256(token);
  const { data, error } = await admin
    .from("coin_recharge_sessions")
    .select("id,user_id,expires_at,revoked_at")
    .eq("token_hash", tokenHash)
    .maybeSingle();
  if (error || !data) return null;
  if (data.revoked_at) return null;
  if (new Date(data.expires_at).getTime() <= Date.now()) return null;
  await admin
    .from("coin_recharge_sessions")
    .update({ last_used_at: new Date().toISOString() })
    .eq("id", data.id);
  return data;
}

async function requireOwner(admin: ReturnType<typeof createClient>, userId: string) {
  const { data } = await admin
    .from("account_roles")
    .select("role")
    .eq("user_id", userId)
    .maybeSingle();
  return String(data?.role ?? "").toLowerCase() === "owner";
}

type RechargePack = {
  id: string;
  label: string;
  coins: number;
  price_cents: number;
  currency: string;
  owner_only: boolean;
};

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function page(
  clientId: string,
  session: string,
  configured: boolean,
  environment: string,
  packs: RechargePack[],
) {
  const paypalScript = configured
    ? `<script src="https://www.paypal.com/sdk/js?client-id=${encodeURIComponent(clientId)}&currency=USD&intent=capture"></script>`
    : "";

  const packCards = packs.length
    ? packs.map((pack, index) => `
<label class="pack ${index === 0 ? "selected" : ""}" data-pack-card>
  <input type="radio" name="pack" value="${escapeHtml(pack.id)}" ${index === 0 ? "checked" : ""} />
  <div>
    <div class="pack-label">${escapeHtml(pack.label)}</div>
    <div class="coins">🪙 ${Number(pack.coins).toLocaleString()} Fame Coins</div>
    <div class="pill">OWNER QA ONLY</div>
  </div>
  <div class="price">$${(Number(pack.price_cents) / 100).toFixed(2)}</div>
</label>`).join("")
    : `<div class="notice">No active owner QA coin packages are available.</div>`;

  const action = configured && packs.length
    ? `<div id="paypal-button-container"></div>`
    : configured
    ? ""
    : `<div class="notice">PayPal Sandbox credentials are not configured on the Fameverse server yet.</div>`;

  const modeCopy = environment === "sandbox"
    ? "PAYPAL SANDBOX · NO REAL MONEY"
    : "PAYPAL LIVE";

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover" />
<title>Fameverse Recharge</title>
${paypalScript}
<style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#09070b;color:#fff;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;min-height:100vh}.wrap{max-width:560px;margin:0 auto;padding:28px 20px 60px}.brand{font-size:12px;letter-spacing:2px;font-weight:900;color:#c699ff}.hero{margin-top:10px;padding:24px;border:1px solid #68408a;border-radius:26px;background:linear-gradient(145deg,#4b236d,#1d1029 55%,#110b17)}h1{margin:0;font-size:30px}.muted{color:#b9adbf;line-height:1.45}.mode{display:inline-block;margin-top:14px;padding:6px 10px;border-radius:999px;background:#24172f;border:1px solid #57386d;color:#d9bbff;font-size:10px;font-weight:900;letter-spacing:.8px}.packs{display:grid;gap:12px;margin:18px 0}.pack{position:relative;display:flex;align-items:center;justify-content:space-between;gap:12px;padding:18px;border-radius:20px;border:1px solid #43304d;background:#17111d;cursor:pointer}.pack.selected{border-color:#a65dff;box-shadow:0 0 0 2px rgba(166,93,255,.15)}.pack input{position:absolute;opacity:0;pointer-events:none}.pack-label{color:#c7b8cf;font-size:12px;font-weight:800;margin-bottom:4px}.coins{font-size:22px;font-weight:900}.price{font-size:20px;font-weight:900;white-space:nowrap}.pill{display:inline-block;margin-top:8px;padding:5px 9px;border-radius:999px;background:#332241;color:#d9bbff;font-size:10px;font-weight:800}.notice{padding:16px;border-radius:16px;background:#2a1c14;border:1px solid #6e4a2f;color:#ffd8ae}.success{padding:18px;border-radius:18px;background:#13271a;border:1px solid #2f6d43;color:#d8ffe3;display:none;margin-bottom:16px}.error{margin-top:14px;color:#ffabb8;font-size:13px;min-height:18px}.fine{font-size:11px;color:#887d90;line-height:1.5;margin-top:20px}.section-title{font-size:12px;color:#a99db1;font-weight:800;letter-spacing:1px;margin-top:24px}
</style>
</head>
<body><main class="wrap">
<div class="brand">FAMEVERSE</div>
<div class="hero">
  <h1>Recharge Fame Coins</h1>
  <p class="muted">Internal Build 16 purchase QA. Choose a test package, complete PayPal Sandbox checkout, then confirm the exact Fame Coins arrive in your Fameverse wallet.</p>
  <div class="mode">${modeCopy}</div>
</div>
<div class="section-title">SELECT QA PACKAGE</div>
<div class="packs">${packCards}</div>
<div id="success" class="success"></div>
${action}
<div id="error" class="error"></div>
<p class="fine">These package values are internal QA values only. They do not lock the public Fame Coin economy. Fameverse credits coins only after the server verifies a completed PayPal capture, and the same capture cannot credit twice.</p>
</main>
<script>
const session=${JSON.stringify(session)};
const errorEl=document.getElementById('error');
const successEl=document.getElementById('success');
for (const card of document.querySelectorAll('[data-pack-card]')) {
  card.addEventListener('click', () => {
    for (const other of document.querySelectorAll('[data-pack-card]')) other.classList.remove('selected');
    card.classList.add('selected');
    const radio=card.querySelector('input[type=radio]');
    if(radio) radio.checked=true;
  });
}
function selectedPack(){
  const radio=document.querySelector('input[name=pack]:checked');
  if(!radio) throw new Error('Select a Fame Coin package first.');
  return radio.value;
}
async function post(payload){
  const response=await fetch(location.pathname+'?session='+encodeURIComponent(session),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({...payload,session})});
  const data=await response.json();
  if(!response.ok) throw new Error(data.error||'recharge-failed');
  return data;
}
${configured && packs.length ? `paypal.Buttons({
  style:{layout:'vertical',shape:'pill',label:'paypal'},
  createOrder:async()=>{errorEl.textContent='';const data=await post({action:'create',pack_id:selectedPack()});return data.order_id;},
  onApprove:async(data)=>{errorEl.textContent='';const result=await post({action:'capture',order_id:data.orderID});successEl.textContent='Payment verified. '+Number(result.credited_coins||0).toLocaleString()+' Fame Coins were credited. Return to Fameverse and refresh your wallet.';successEl.style.display='block';document.getElementById('paypal-button-container').style.display='none';return result;},
  onCancel:()=>{errorEl.textContent='Payment cancelled. No Fame Coins were credited.';},
  onError:(error)=>{errorEl.textContent=error?.message||'PayPal could not complete this checkout. No Fame Coins were credited.';}
}).render('#paypal-button-container');` : ""}
</script></body></html>`;
}

Deno.serve(async (req: Request) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const paypalClientId = Deno.env.get("PAYPAL_CLIENT_ID") ?? "";
  const paypalSecret = Deno.env.get("PAYPAL_CLIENT_SECRET") ?? "";
  const paypalEnvironment = (Deno.env.get("PAYPAL_ENVIRONMENT") ?? "sandbox").toLowerCase() === "live" ? "live" : "sandbox";
  if (!supabaseUrl || !serviceRoleKey) return json(503, { error: "backend-not-configured" });

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const requestUrl = new URL(req.url);
  let sessionToken = requestUrl.searchParams.get("session") ?? "";

  if (req.method === "POST") {
    let body: Record<string, unknown> = {};
    try {
      body = await req.json();
    } catch {
      return json(400, { error: "invalid-json" });
    }

    sessionToken = String(body.session ?? sessionToken);
    const session = await sessionContext(admin, sessionToken);
    if (!session) return json(401, { error: "invalid-or-expired-recharge-session" });
    if (!(await requireOwner(admin, session.user_id))) return json(403, { error: "recharge-owner-qa-only" });
    if (!paypalClientId || !paypalSecret) return json(503, { error: "paypal-not-configured" });

    const action = String(body.action ?? "");
    if (action === "create") {
      const packId = String(body.pack_id ?? "");
      const { data: pack, error: packError } = await admin
        .from("coin_recharge_packs")
        .select("id,label,coins,price_cents,currency,active,owner_only")
        .eq("id", packId)
        .eq("active", true)
        .maybeSingle();
      if (packError || !pack) return json(404, { error: "recharge-pack-not-found" });
      if (!pack.owner_only) return json(403, { error: "qa-pack-required" });

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
      if (rechargeError || !recharge) return json(500, { error: "recharge-order-create-failed" });

      try {
        const accessToken = await paypalAccessToken(paypalClientId, paypalSecret, paypalEnvironment);
        const requestId = `fv-recharge-${recharge.id}`;
        const value = (Number(pack.price_cents) / 100).toFixed(2);
        const paypalResponse = await fetch(`${paypalBase(paypalEnvironment)}/v2/checkout/orders`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            "PayPal-Request-Id": requestId,
          },
          body: JSON.stringify({
            intent: "CAPTURE",
            purchase_units: [{
              reference_id: recharge.id,
              custom_id: recharge.id,
              description: `${pack.label} — ${pack.coins} Fame Coins`,
              amount: { currency_code: pack.currency, value },
            }],
          }),
        });
        const paypalOrder = await paypalResponse.json();
        if (!paypalResponse.ok || !paypalOrder.id) {
          await admin
            .from("coin_recharge_orders")
            .update({ status: "failed", updated_at: new Date().toISOString() })
            .eq("id", recharge.id);
          return json(502, { error: "paypal-order-create-failed" });
        }
        await admin
          .from("coin_recharge_orders")
          .update({ provider_order_id: paypalOrder.id, updated_at: new Date().toISOString() })
          .eq("id", recharge.id);
        return json(201, { order_id: paypalOrder.id });
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
      if (!orderId) return json(400, { error: "missing-paypal-order-id" });
      const { data: recharge, error: lookupError } = await admin
        .from("coin_recharge_orders")
        .select("id,user_id,amount_cents,currency,coins,status,provider_order_id")
        .eq("provider_order_id", orderId)
        .eq("user_id", session.user_id)
        .maybeSingle();
      if (lookupError || !recharge) return json(404, { error: "recharge-order-not-found" });
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
        const accessToken = await paypalAccessToken(paypalClientId, paypalSecret, paypalEnvironment);
        const captureResponse = await fetch(`${paypalBase(paypalEnvironment)}/v2/checkout/orders/${encodeURIComponent(orderId)}/capture`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            "PayPal-Request-Id": `fv-capture-${recharge.id}`,
          },
          body: "{}",
        });
        const captured = await captureResponse.json();
        if (!captureResponse.ok || captured.status !== "COMPLETED") {
          return json(502, { error: "paypal-capture-not-completed" });
        }
        const capture = captured.purchase_units?.[0]?.payments?.captures?.[0];
        const captureId = String(capture?.id ?? "");
        const amountValue = Number(capture?.amount?.value ?? NaN);
        const amountCents = Math.round(amountValue * 100);
        const currency = String(capture?.amount?.currency_code ?? "");
        if (!captureId || amountCents !== Number(recharge.amount_cents) || currency !== recharge.currency) {
          return json(409, { error: "paypal-capture-mismatch" });
        }
        const { data: finalized, error: finalizeError } = await admin.rpc("finalize_coin_recharge", {
          p_recharge_id: recharge.id,
          p_provider_order_id: orderId,
          p_provider_capture_id: captureId,
          p_amount_cents: amountCents,
          p_currency: currency,
        });
        if (finalizeError) return json(500, { error: "wallet-credit-failed" });
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
  }

  if (req.method !== "GET") return json(405, { error: "method-not-allowed" });
  const session = await sessionContext(admin, sessionToken);
  if (!session) {
    return html(401, "<h1>Recharge session expired</h1><p>Return to Fameverse and open Recharge again.</p>");
  }
  if (!(await requireOwner(admin, session.user_id))) {
    return html(403, "<h1>Recharge unavailable</h1>");
  }

  const { data: packs, error: packError } = await admin
    .from("coin_recharge_packs")
    .select("id,label,coins,price_cents,currency,owner_only")
    .eq("active", true)
    .eq("owner_only", true)
    .order("sort_order", { ascending: true })
    .order("price_cents", { ascending: true });

  if (packError) {
    return html(500, "<h1>Recharge unavailable</h1><p>Fameverse could not load the QA coin packages.</p>");
  }

  return html(
    200,
    page(
      paypalClientId,
      sessionToken,
      Boolean(paypalClientId && paypalSecret),
      paypalEnvironment,
      (packs ?? []) as RechargePack[],
    ),
  );
});
