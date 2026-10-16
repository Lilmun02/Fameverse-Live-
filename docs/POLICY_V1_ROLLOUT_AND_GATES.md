# Fameverse policy v1 — implementation and release gates

**Status: DRAFT / FEATURE OFF / UNDEPLOYED / SECURITY REVIEW REQUIRED.**
**Branch:** `feature/policy-acceptance-account-integrity-oct15`
**Base:** `integration/sep27-big-update` @ `7bbe68c933d96d1e303b32521ac18bbad27d2d81`

## Implemented as a reviewable candidate
- Versioned policy documents, account standing, violation case/audit records and verified group membership (max two accounts per reviewed person): `docs/POLICY_ENFORCEMENT_STAGING_SCHEMA.sql`.
- Authenticated read of current policy via `fv_get_policy_requirement`, signed-in acceptance via `fv_accept_current_policy`, server-side unique `user_id,version`, recheck before entering app. No client writes to an acceptance row and no local preferences used as legal evidence.
- Native gate: `lib/features/auth/fameverse_policy_agreement_gate.dart` routed from `app/fameverse_app.dart`.
- Web gate: `src/components/auth/PolicyAgreementGate.jsx` wrapped around signed-in shell via `src/App.jsx`.
- Expanded legal terms in existing native and browser Settings pages. Legal/privacy counsel review required before formal publication.
- Native source regression contract test. No financial transactions or test gifts were executed.

## Critical rollout protection
- **Do not run this SQL in production as part of code review.** It is staged SQL, not an applied migration. Follow the project's approved migration generator / migration versioning workflow.
- The proposed row is **active=false**. Publishing a version after legal review is a separate owner-approved operation.
- Both clients gate behind OFF-by-default flags: `--dart-define=FAMEVERSE_POLICY_GATE_ENABLED=true` for Flutter and `VITE_FAMEVERSE_POLICY_GATE_ENABLED=true` for web.
- Do not enable flags until backend RPCs exist, policy has been published, user accounts can acknowledge and sign out without a lockout, and multi-account QA has passed. An unavailable RPC must not count as acceptance.
- No existing user consent is fabricated or backfilled. Every active user must individually check the box and have a recorded unique policy-version acknowledgment.
- Account linking is **review-only identity evidence**, never infer owner identity from email prefixes, username, devices or IP alone. Two-account cap applies to verified groups; detection of aliases using separate identities needs a future consent-aware verification process.
- `fv_financial_permissions` is a read-only proposal for downstream gift and payout checks. **It is not connected to the current money RPCs**; automatic holds and provider-webhook fraud ingestion are NOT complete. They require separate audited changes and must block at the server boundary, not via a UI-only disabled button.
- Account standings and violation cases are private and cannot be user-modified. Moderation and appeals require explicit approved admin-only endpoints and web Owner Control Center UI; neither are implemented by this source-only candidate.
- Good-faith chargebacks and legitimate refunds are not automatically classified as fraud. A permanent ban must follow verified severe/repeated abuse and owner review.
- No Stripe/PayPal/IAP accounts accessed. No gift sends, charges, debits or payouts executed.

## Acceptance QA gates
1. SQL reviewed for policy authorization, RLS and privilege exposure. Apply to isolated staging only under approved migration procedure.
2. Test two independent identities: new and existing users cannot bypass active consent; a repeated acceptance is idempotent and stored against the authenticated user ID; new version prompts again.
3. Unavailable server/auth expiry handling allows signout/retry; no ghost consent, bypass or stale-user leak.
4. Test web+native interaction, accessibility, full policy text and mobile layouts. Versioned text in client Settings must match legally published server documents.
5. Verify at-most-two group logic including concurrent requests and update moves. Do not auto-link accounts based solely on superficial similarities.
6. Verify financial holds after reviewing gift/payout RPCs with zero real/sandbox purchases and no live transfer; use isolated unit and pure database contract fixtures only, never real account balances.
7. Founder reviews final copy, privacy data retention, legal/provider terms and rollout flags. Release strictly separate from Live repair PR #86.

**This branch is not merged, deployed, activated or available to testers.**
