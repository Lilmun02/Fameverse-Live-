# Fameverse Owner Command Center — preview-only access

Owner-requested workflow: **existing Fameverse account sign-in → fresh email verification → server-enforced approved IP**. There is no second owner security code, no hash generator, and no self-service environment-variable wizard.

The web-only `/owner` route is not linked from public or native navigation. Its server endpoint, `/api/owner/control`, checks authenticated Supabase JWT, `auth.users.email_confirmed_at`, the existing `public.account_roles.role = 'owner'`, an explicitly approved Vercel request IP from `x-vercel-forwarded-for`, and a fresh signed `amr` email OTP or email-link authentication method (last 10 minutes). No user metadata, browser storage, or self-reported IP is accepted for authorization.

For email verification the owner selects **Send verification email**. The preview sends an email via Supabase `signInWithOtp({ options: { shouldCreateUser: false, emailRedirectTo: currentPreview + '/owner' }})`. If Supabase email template sends a magic link, the owner clicks it; if configured to send a numeric OTP, the page accepts that too. The current Supabase Auth redirect allowlist/email template may require verification for the preview origin. Check it without altering other auth emails. The backend requires a verified recent `amr` claim before any financial data returns.

### Single IP approval

The only owner access setting is `OWNER_ALLOWED_IPS`, an exact public IP (not a broad range). It is stored privately in Vercel **Preview only** and scoped to branch `feature/web-owner-command-center-gate-20261107`. The code does not set an IP automatically. While unset, the owner page shows `IP approval required` and the server-observed IP **only after verified Fameverse owner sign-in**; no dashboard access is granted. The owner must expressly approve that IP before the assistant can add it through Vercel. Never share it publicly, never infer it from geolocation, never default to allow-all, and never configure production.

Public/human IPs can change with Wi-Fi, VPN or mobile connections, so any IP change must be re-approved through the normal owner-controlled change process. Vercel's platform-wide enterprise Trusted IPs feature is separate and is not required for protecting the owner API route. We protect the owner API at application level.

No schema changes, service-role keys, payouts, refunds, bans, native app or production deployments. The owner finance RPC is read-only and independently enforces the owner role.

### Acceptance testing

- Verify unauthenticated/non-owner/unverified-email/unapproved-IP users cannot retrieve data.
- Verify a password-only session cannot satisfy the email OTP step.
- Verify actual emailed link or OTP arrives and issues `amr` suitable for server verification; do not claim until tested.
- Verify only approved exact IP can see the owner summary.
- Verify deployed preview /owner and /api/owner/control; no changes to fameverse.app.
