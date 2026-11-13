# Owner Command Center capability audit

Audited starting point: PR #112, `ea42ea1b92d1ff02542c7f349f3e098c89afa21a`.
Sources: CEO/CTO specification comment 6729414764 and handoff 6764557435.

“Verified” below means inspected source and local automated tests, not a live
owner session or deployed database validation. The handoff states the preview
shares a production database. No database changes or purchase code are authorized.

| Section | Existing authoritative read | Preview-only / missing backend |
| --- | --- | --- |
| Overview | Profile count, live count with the shared 45-second heartbeat cutoff, finance RPC | Case, badge, policy, operational totals and reconciled detail links missing |
| User Management | Paginated/searchable profiles | Full role/standing/history and joined cases missing; enforcement validates only |
| Live Operations | Live room metadata with the same freshness cutoff | Co-host/incident joins missing; kick/mute/end validate only |
| Moderation | Read adapter for staged owner_cases (moderation, appeals, policy, integrity, security) | Schema unactivated; evidence, sanctions, reversals and authoritative write gates missing |
| Gifts & Coins | Existing published gift-catalog RPC | Evidence/receipt/balance/provenance investigation missing; grants validate only; purchases frozen |
| Finance & Payouts | Existing moderation queue and owner finance summary RPCs | Holds/releases validate only; no live payouts or transfers |
| Owner Funding | Owner reward-control summary RPC | Allocations validate only; no wallet credits or transfers |
| Reports & Analytics | Existing rolling 24-hour / 7-day rankings RPC | UTC/Sunday and all-time contracts not deployed; native Build 47/PR #101 untouched |
| Badge Requests | Existing creator-verification moderation queue | Other badge evidence/intake missing; approvals/rejections validate only |
| Support & Cases | Read adapter for existing web beta_feedback, gated on staged owner_cases schema | Schema/policy unactivated; assignment, notes, responses, attachments and lifecycle writes missing |
| Policy & Compliance | Active published notices | Per-user acceptance, authoritative restriction gates and joined investigations missing |
| System Controls | Read-only app release state | Health/flags and audited maintenance/rollback commands missing; native settings untouched |
| Audit Logs | Read adapter for staged owner_audit_events | Durable table unactivated; immutable write/idempotency/reversal contract missing; local history is not audit |

## Shared communication contract

Every read and validation passes through the existing same-origin HTTPS,
confirmed-account, authoritative owner-role and approved-IP checks. No client role
or supplied IP grants server access. Navigation refetches protected data. A 401 or
403 clears private records, action results, temporary history and the workspace.

Use `profiles.id` for subjects, `live_rooms.id` for broadcasts, payout IDs for
requests, `beta_feedback.id` for intake, `owner_cases.id` for cross-section case
correlation and `owner_audit_events.id` for durable events. Never treat one ID type
as another. Read links must preserve the case or target filter in the URL and the
protected API request. Missing schema/permissions must show unavailable rather
than an empty inbox or invented totals.

All existing commands are dry-run validation: `applied:false`, `recorded:false`.
A request ID is not an idempotent applied-command or audit record. High-impact
commands must remain disabled for real execution until a separately approved
isolated backend implements atomic case/action/audit transactions, replay-safe
idempotency, target checks, notice/appeal behavior and rollback. No SQL in docs is
an applied migration; staging alone is not end-to-end functionality.

## CTO repairs re-reviewed

- `ee9012a`: top-header entry removed; owner account-menu link retained.
- `fa3835f`: Overview and Live share `LIVE_PRESENCE_STALE_MS = 45000` and filter heartbeat at query time.
- `cedd0ba`: 401/403 reads and validations lock before attempting JSON parsing, no private response cache across navigation. Local browser regression fixtures exercise both status codes and non-JSON bodies.
- `ea42ea1`: Support/Audit reads stay unavailable without the protected staged stores; no browser write grants, no applied SQL.

Live verification still needs allowed backend egress and a real authorized owner
session on the approved Preview IP. Schema activation requires separate CEO
approval for an isolated database, including cost review; never apply this SQL to
production or describe undeployed features as working.

## Repairs after the CTO starting point

Support/Audit render actual contracted fields and carry protected case/target
filters across links and browser history. Moderation now uses the staged case
store instead of relabeling the profile directory as an enforcement queue. It
reports unavailable when the store is absent. All three remain deployment-blocked.

Control changes preserve room/member/payout target identity. Pending validations
cannot be submitted twice or leak a late result across navigation; cancellation
and session cleanup discard them. Target roles hidden by RLS fail closed rather
than qualifying as verified non-owners. The secure access handshake is coalesced
under StrictMode, bounded to ten seconds, and never cached across a retry.
