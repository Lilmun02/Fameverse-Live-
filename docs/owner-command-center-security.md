# Owner Command Center — preview security gate

This feature is **web-only**, read-only and currently intended for an isolated preview branch. It must not be merged or promoted to fameverse.app without the owner's explicit authorization.

## Access conditions (all required)

1. A verified Supabase signed-in session with the existing `public.account_roles.role = 'owner'` row.
2. A server-side Vercel allowlist of exact IPv4 or IPv6 addresses (`OWNER_ALLOWED_IPS`).
3. A server-side scrypt hash of a separate long owner access code (`OWNER_ACCESS_CODE_SALT` and `OWNER_ACCESS_CODE_SCRYPT_HASH`).
4. Request-origin and trusted Vercel source IP checks, repeated for every sensitive backend request.

No plaintext code, database service-role credential or owner IP is embedded in the browser, repository, test fixtures or preview response. API failures deny access without returning owner data. Never use user-controlled JWT user_metadata for authorization.

### Guided setup — private preview only

The preview `/owner` page now offers a three-step setup wizard once the user is signed in with an existing account whose `account_roles.role` is exactly `owner`. No login to a second account is required.

1. Owner chooses their own unique **16–128 character** code, confirms it, and saves it in a password manager. The code is submitted over same-origin HTTPS to the preview API `POST /api/owner/control` with `action: "prepare"`. The API authenticates the Supabase JWT, re-verifies the `owner` role, checks Origin, detects the trusted Vercel IP header, and generates a random 24-byte salt and scrypt hash. **The plaintext code is never returned, persisted or logged**. The operation is denied if a valid owner gate is already configured.
2. Wizard displays the three variables `OWNER_ALLOWED_IPS`, `OWNER_ACCESS_CODE_SALT`, and `OWNER_ACCESS_CODE_SCRYPT_HASH` with copy buttons and a link to the project's Environment Variables. Save **only** in Vercel → Settings → Environment Variables, environment **Preview**, restricted to the branch `feature/web-owner-command-center-gate-20261107`. Never send credentials to ChatGPT.
3. Redeploy the preview branch so it picks up the newly provisioned environment variables, then refresh `/owner` and verify status. **Do not** configure or deploy Production.

If the verified IP cannot be detected, preparation fails closed with an error; do not guess an IP. Changing public IP requires owner-controlled Vercel allowlist update and preview redeploy. No alternate bypass is available.

No security code is active until the owner has completed the Vercel setup and preview redeploy. The dashboard remains locked by default.

### Preview behavior before setup

GET /api/owner/control returns only `{ "configured": false }` until owner-controlled preview secrets are provided. The web UI displays an owner-only guided setup with no operational dashboard or owner data. The security-code unlock form appears only after configuration is detected. If the check fails, it stays locked. The code form appears only once GET reports the server is fully configured. Never ask the owner to invent or paste the code in chat.

### Current functionality

After the complete gate succeeds, the API uses the caller's JWT and the preexisting `get_owner_finance_control_summary` Supabase RPC. It returns a whitelist of read-only fields. The RPC itself independently enforces `owner` role authorization. There are no payouts, refunds, bans, coin grants, role edits or moderation actions in this feature.

### Release acceptance checklist

- Verify branch-specific preview only; production commit must remain unchanged.
- Verify 403 for guest, non-owner, unapproved IP or invalid code; verify 503 with missing configuration.
- Verify with a real authorized owner only after the owner privately provisions code and IP; do not claim working authentication before that.
- Check that no summary data is present in HTML or bundle, no service-role secret is included, and the native TestFlight app is unmodified.
- Validate mobile/desktop read-only layout, source-IP consistency, token expiry, no caching and no owner data in console logs.
