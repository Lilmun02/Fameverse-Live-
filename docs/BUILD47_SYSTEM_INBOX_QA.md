# Build 47 native System Inbox candidate

This isolated branch connects the existing native Profile to a read-only
System Activity Inbox. It uses only active records from the existing
app_update_notices table and the authoritative account-specific policy
state already supplied to the native shell. It **does not** enable DMs,
private inbox tables, receipts, or send operations.

Source safeguards:
- Repository requires client.auth.currentUser.id to match the requested user.
- Existing active-notices RLS verified read-only; no schema or grant changes.
- Policy card is displayed only when server-verified accountId matches userId.
- User switches and late responses are discarded via request generation.
- No synthetic messages or unread counters; failed requests show retry.

QA required: flutter format/analyze/tests, Android debug, unsigned iOS,
iPhone inbox entry, notices/empty/error/retry, policy decline and expiry,
account sign-out/account switching. The newer Flutter/Supabase v3 breaking
release is NOT adopted; this patch retains existing dependency versions.

This is only a draft source candidate. It is not in PR #101, not in any
TestFlight build, and not evidence the private-message backlog is done.
No funds, gifts, Apple IAP, live policy backend, ranking SQL, Codemagic,
workflow, native signing, deployment or production data were modified.
