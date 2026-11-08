# Owner Command Center — preview security gate

This feature is **web-only**, read-only and currently intended for an isolated preview branch. It must not be merged or promoted to fameverse.app without the owner's explicit authorization.

## Access conditions (all required)

1. A verified Supabase signed-in session with the existing `public.account_roles.role = 'owner'` row.
2. A server-side Vercel allowlist of exact IPv4 or IPv6 addresses (`OWNER_ALLOWED_IPS`).
3. A server-side scrypt hash of a separate long owner access code (`OWNER_ACCESS_CODE_SALT` and `OWNER_ACCESS_CODE_SCRYPT_HASH`).
4. Request-origin and trusted Vercel source IP checks, repeated for every sensitive backend request.

No plaintext code, database service-role credential or owner IP is embedded in the browser, repository, test fixtures or preview response. API failures deny access without returning owner data. Never use user-controlled JWT user_metadata for authorization.

### Setup (owner-controlled; not performed by the assistant)

Set the three `OWNER_*` variables **privately in Vercel for the intended preview branch**, not in chat. The salt must be a random value of at least 16 characters; the hash is lowercase hex of Node `scryptSync(accessCode, salt, 64)`. Use a strong unique code of at least 12 characters, and never store or commit the plaintext. Do not place the variables on production until its release is authorized.

If any variable is unset, malformed, or the current IP is not allowlisted, `POST /api/owner/control` returns a denied/unconfigured response and no data. `GET` is unsupported. The page is accessible only via the direct `/owner` URL, not the public or mobile navigation.

### Current functionality

After the complete gate succeeds, the API uses the caller's JWT and the preexisting `get_owner_finance_control_summary` Supabase RPC. It returns a whitelist of read-only fields. The RPC itself independently enforces `owner` role authorization. There are no payouts, refunds, bans, coin grants, role edits or moderation actions in this feature.

### Release acceptance checklist

- Verify branch-specific preview only; production commit must remain unchanged.
- Verify 403 for guest, non-owner, unapproved IP or invalid code; verify 503 with missing configuration.
- Verify with a real authorized owner only after the owner privately provisions code and IP; do not claim working authentication before that.
- Check that no summary data is present in HTML or bundle, no service-role secret is included, and the native TestFlight app is unmodified.
- Validate mobile/desktop read-only layout, source-IP consistency, token expiry, no caching and no owner data in console logs.
