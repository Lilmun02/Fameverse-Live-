import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const headers = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
};

function page(status: "approved" | "cancelled" | "unknown") {
  const approved = status === "approved";
  const cancelled = status === "cancelled";
  const title = approved
    ? "PayPal approved"
    : cancelled
    ? "PayPal cancelled"
    : "PayPal return";
  const body = approved
    ? "Return to Fameverse and tap Complete sandbox purchase. Fame Coins are credited only after Fameverse verifies the PayPal capture."
    : cancelled
    ? "No Fame Coins were credited. Return to Fameverse when you are ready."
    : "Return to Fameverse to continue.";

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta name="color-scheme" content="dark" />
  <title>${title} · Fameverse</title>
  <style>
    html,body{margin:0;min-height:100%;background:#09070b;color:#f7f0fa;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
    main{min-height:100vh;display:grid;place-items:center;padding:24px;box-sizing:border-box}
    section{width:min(440px,100%);padding:28px;border:1px solid #4a3155;border-radius:24px;background:linear-gradient(145deg,#271334,#130d18 58%,#09070b);box-sizing:border-box}
    .mark{width:58px;height:58px;border-radius:50%;display:grid;place-items:center;background:#4b2465;color:#e2bcff;font-size:30px;font-weight:900;font-style:italic;margin-bottom:20px}
    h1{margin:0 0 10px;font-size:26px}p{margin:0;color:#b9aec1;line-height:1.55}.note{margin-top:18px;color:#8f8296;font-size:13px}
  </style>
</head>
<body><main><section><div class="mark">F</div><h1>${title}</h1><p>${body}</p><p class="note">This page never credits coins and never handles creator payouts.</p></section></main></body>
</html>`;
}

Deno.serve((req: Request) => {
  if (req.method !== "GET") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { ...headers, "Content-Type": "text/plain; charset=utf-8" },
    });
  }

  const raw = new URL(req.url).searchParams.get("status")?.toLowerCase();
  const status = raw === "approved" || raw === "cancelled" ? raw : "unknown";
  return new Response(page(status), { status: 200, headers });
});
