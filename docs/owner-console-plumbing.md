# Owner console API sections — preview contract

The authenticated `/api/owner/console` endpoint requires **exactly one configured Vercel request IP**, a verified Supabase session, a confirmed email and a database `owner` role. Request origin and every response are protected independently; no privileged data is embedded in the public browser bundle.

Supported read sections: overview, users, live, moderation, gifts, finance, funding, reports, badges, policy, support, system, audit. Where a secure owner-read workflow is not yet present, the API returns an explicit `availability: requires_isolated_backend` state. It never invents sample users, finances or moderation cases.

**Preview action plumbing:** Validated `preview_action` requests cover warn, suspend, ban, permanent ban, unban, kick live, end live, mute live, feature restriction, restore access, activity review, badge approve/reject, hold/release payout, fraud review, test-coin grants, reserve allocation, update notice publishing, staff permissions, system maintenance and support review. Actions require a reason and target identifier when applicable, but **return `applied:false, recorded:false, mode:'preview'`**. This branch shares a production Supabase project; no preview click can mutate real users, balances, payouts, live rooms or policies. No permanent audit events are created. This must remain obvious in the UI.

Before any action can actually execute: provision an isolated Supabase development environment (review costs and authorization), implement RLS/owner-only audited action RPCs, add idempotency, reason, notification, appeal and enforcement process, test there, and secure a separate owner-approved production rollout. An already existing owner finance RPC is read-only and is safe to call; other read queues operate under current RLS.

Do not enable destructive writes, direct data grants, or production migrations from this preview without explicit authorization.
