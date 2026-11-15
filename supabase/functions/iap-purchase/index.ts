import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { Buffer } from "node:buffer";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@3.1.0";

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

const bundleId = "com.fameverse.live";
const appleRootUrls = [
  "https://www.apple.com/appleca/AppleIncRootCertificate.cer",
  "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer",
  "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
] as const;

let rootCertificatePromise: Promise<Buffer[]> | null = null;

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

async function loadAppleRootCertificates(): Promise<Buffer[]> {
  rootCertificatePromise ??= Promise.all(
    appleRootUrls.map(async (url) => {
      const response = await fetch(url, { redirect: "follow" });
      if (!response.ok) {
        throw new Error(`apple-root-download-failed:${response.status}`);
      }
      return Buffer.from(await response.arrayBuffer());
    }),
  );
  return await rootCertificatePromise;
}

type VerifiedAppleTransaction = {
  environment: "Sandbox" | "Production";
  transactionId: string;
  originalTransactionId: string | null;
  productId: string;
  appAccountToken: string | null;
  purchaseDate: string | null;
};

function millisToIso(value: unknown): string | null {
  const millis = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(millis) || millis <= 0) return null;
  return new Date(millis).toISOString();
}

async function verifyAppleTransaction(
  signedTransaction: string,
): Promise<VerifiedAppleTransaction> {
  const roots = await loadAppleRootCertificates();

  const tryVerifier = async (
    environment: Environment,
    appAppleId?: number,
  ): Promise<VerifiedAppleTransaction> => {
    const verifier = new SignedDataVerifier(
      roots,
      true,
      environment,
      bundleId,
      appAppleId,
    );
    const decoded = await verifier.verifyAndDecodeTransaction(signedTransaction);
    const row = decoded as unknown as Record<string, unknown>;

    const transactionId = String(row.transactionId ?? "").trim();
    const productId = String(row.productId ?? "").trim();
    const originalTransactionId = String(
      row.originalTransactionId ?? "",
    ).trim();
    const appAccountToken = String(row.appAccountToken ?? "").trim();
    const revocationDate = row.revocationDate;
    const quantity = Number(row.quantity ?? 1);

    if (!transactionId || !productId) {
      throw new Error("apple-transaction-fields-missing");
    }
    if (revocationDate != null) {
      throw new Error("apple-transaction-revoked");
    }
    if (!Number.isFinite(quantity) || quantity !== 1) {
      throw new Error("apple-transaction-quantity-invalid");
    }

    return {
      environment:
        environment === Environment.PRODUCTION ? "Production" : "Sandbox",
      transactionId,
      originalTransactionId: originalTransactionId || null,
      productId,
      appAccountToken: appAccountToken || null,
      purchaseDate: millisToIso(row.purchaseDate),
    };
  };

  try {
    return await tryVerifier(Environment.SANDBOX);
  } catch (sandboxError) {
    const rawAppId = Deno.env.get("APPLE_APP_ID")?.trim() ?? "";
    const appAppleId = Number(rawAppId);
    if (!rawAppId || !Number.isSafeInteger(appAppleId) || appAppleId <= 0) {
      throw sandboxError;
    }
    return await tryVerifier(Environment.PRODUCTION, appAppleId);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method-not-allowed" });

  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return json(401, { error: "missing-auth" });
  }

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

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json(400, { error: "invalid-json" });
  }

  const platform = String(body.platform ?? "").toLowerCase();
  if (platform !== "ios") {
    return json(400, { error: "unsupported-store-platform" });
  }

  const signedTransaction = String(body.signed_transaction ?? "").trim();
  if (
    signedTransaction.length < 100 ||
    signedTransaction.length > 50000 ||
    signedTransaction.split(".").length !== 3
  ) {
    return json(400, { error: "invalid-apple-signed-transaction" });
  }

  let verified: VerifiedAppleTransaction;
  try {
    verified = await verifyAppleTransaction(signedTransaction);
  } catch (error) {
    console.error("Apple IAP verification failed", error);
    return json(400, { error: "apple-transaction-verification-failed" });
  }

  // Every Fameverse StoreKit 2 purchase is started with the authenticated
  // profile UUID as applicationUserName. StoreKit maps a UUID to appAccountToken.
  // Reject a missing/mismatched token so a signed purchase cannot be replayed
  // onto a different Fameverse account.
  if (verified.appAccountToken !== user.id) {
    return json(403, { error: "apple-account-token-mismatch" });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: product, error: productError } = await admin
    .from("fame_coin_store_products")
    .select("product_id, coins, active")
    .eq("platform", "ios")
    .eq("product_id", verified.productId)
    .maybeSingle();
  if (productError) return json(500, { error: "store-product-lookup-failed" });
  if (!product || product.active !== true) {
    return json(400, { error: "unknown-store-product" });
  }

  const { data: finalized, error: finalizeError } = await admin.rpc(
    "finalize_fame_coin_store_purchase",
    {
      p_user_id: user.id,
      p_platform: "ios",
      p_product_id: verified.productId,
      p_transaction_id: verified.transactionId,
      p_original_transaction_id: verified.originalTransactionId,
      p_environment: verified.environment,
      p_app_account_token: verified.appAccountToken,
      p_purchase_date: verified.purchaseDate,
    },
  );
  if (finalizeError) {
    console.error("Fame Coin purchase finalization failed", finalizeError);
    return json(500, { error: "store-purchase-finalize-failed" });
  }

  const row = Array.isArray(finalized) ? finalized[0] : finalized;
  return json(200, {
    status: "completed",
    product_id: verified.productId,
    transaction_id: verified.transactionId,
    environment: verified.environment,
    credited_coins: Number(row?.credited_coins ?? product.coins ?? 0),
    wallet_balance: Number(row?.wallet_balance ?? 0),
    already_completed: row?.already_completed === true,
  });
});
