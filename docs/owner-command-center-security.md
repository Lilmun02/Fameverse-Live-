# Fameverse Owner Command Center — preview only

**Owner-approved workflow:** sign in with the existing Fameverse account; the server then verifies the account's confirmed email, the authoritative owner role and **exactly one approved public IP**. No security code, extra email one-time code, separate login, manual hash or setup wizard.

## Server gate
- Vercel project environment variable `OWNER_ALLOWED_IPS` is encrypted, scoped to Preview and `feature/web-owner-command-center-gate-20261107`; currently set privately to the one address expressly supplied and approved by the owner. Never commit an address to source.
- POST `/api/owner/control` is the **only** supported API operation. It rejects all requests without a valid IP allowlist or when the Vercel-provided `x-vercel-forwarded-for` header doesn't match, including requests without authentication. Missing or ambiguous IPs fail closed. Off-IP requests get HTTP 403 and **no data**.
- From the approved IP, POST requires same-origin HTTPS, a valid Supabase access-token JWT authenticated by `auth.getUser(token)`, a confirmed account email, and an existing `public.account_roles.role = 'owner'` row. The server ignores browser-provided roles and user-editable metadata. No service-role credential is used.
- Only the existing read-only `get_owner_finance_control_summary` RPC is called; its output is limited to four whitelisted fields. The API sends no-store headers. The browser locks read-only figures after five minutes or when its tab is hidden.
- The web route `/owner` may still serve a public HTML shell (because it is a SPA). **The owner API and its sensitive data are blocked** from any unapproved IP. This is not a global Supabase-login or project-wide IP policy; it is the scoped web Owner Command Center protection.

## Verification
- Unit-test rejected IPs, missing IPs, missing allowlist, guest/invalid token, unconfirmed email, non-owner account, and allowed IP with verified owner account.
- Check Vercel Preview build on this exact branch and test blocked API requests outside approved network. Verify live account sign-in and owner summary **from an approved IP** as final acceptance; do not call it end-to-end verified from tests alone.
- Don't change production fameverse.app, Supabase email templates, Auth settings, database schema, native or TestFlight setup.
- If the owner's public IP changes, access is denied until the new address is explicitly approved and the Preview environment variable is updated. Never auto-approve a new IP or enable allow-all.

## Other owner credentials
The database currently has multiple accounts carrying the owner role. This preview relies on that existing role table. Restricting the panel to just one user ID is a separate authorization decision and should not be guessed.
