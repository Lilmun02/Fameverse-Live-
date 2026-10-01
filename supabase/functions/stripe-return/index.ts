import "jsr:@supabase/functions-js/edge-runtime.d.ts";

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

Deno.serve((req: Request) => {
  const url = new URL(req.url);
  const status = url.searchParams.get("status") === "success" ? "success" : "cancelled";
  const title = status === "success" ? "Payment received" : "Checkout cancelled";
  const body = status === "success"
    ? "Stripe is confirming your payment with Fameverse. Return to the app and your Fame Coin balance will refresh after the signed webhook is verified."
    : "No Fame Coins were purchased. You can return to Fameverse and try again whenever you are ready.";

  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>Fameverse — ${escapeHtml(title)}</title>
  <style>
    :root { color-scheme: dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #0c0810; color: #f7effb; padding: 24px; box-sizing: border-box; }
    main { width: min(520px, 100%); background: linear-gradient(145deg, #321643, #17101e); border: 1px solid #693b80; border-radius: 24px; padding: 28px; box-sizing: border-box; box-shadow: 0 24px 70px rgba(0,0,0,.35); }
    .badge { display: inline-block; padding: 7px 10px; border-radius: 999px; background: #51276b; color: #e7c8ff; font-size: 12px; font-weight: 800; letter-spacing: .06em; }
    h1 { margin: 16px 0 10px; font-size: 30px; }
    p { margin: 0; color: #cbbfd0; line-height: 1.55; }
    .hint { margin-top: 20px; font-size: 13px; color: #9f94a4; }
  </style>
</head>
<body>
  <main>
    <span class="badge">FAMEVERSE · STRIPE CHECKOUT</span>
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(body)}</p>
    <p class="hint">You can close this browser tab and return to Fameverse.</p>
  </main>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    },
  });
});
