# Fameverse Native Inbox — isolated QA branch

**State:** UI candidate and a **STAGING-ONLY** SQL design. Neither migration nor notification delivery has been deployed. Do not merge, ship, or enable this feature as a complete messaging service.

## Implementation prepared on this branch

- Messages tab: genuine Supabase account-scoped conversations, latest message previews, unread counts, refresh, profile search, conversation creation, history, send and read receipt.
- Activity tab: private server-authored notices, unread status and read receipts. **Actual server notice delivery is not yet implemented**, so an empty feed does not prove it works.
- UI dependency injection and widget tests for empty/populated, backend unavailable and account switching.
- Flag: `FAMEVERSE_NATIVE_INBOX_ENABLED` defaults to **false**; the Profile entry is hidden without an explicit enabled build and deployed secure backend.
- `docs/NATIVE_INBOX_STAGING_SCHEMA.sql` is a **review candidate**, not an executable production migration. Contains owner-only RLS, sorted two-party conversations, server-checked sender identity, reciprocal blocks, message rate limiting, private reports, client-read-only notifications, and read receipts. A qualified Postgres security review is still required.

## Privacy/security checklist before any enablement

1. Generate an actual Supabase CLI migration only **after approval**, from the reviewed staging SQL. Do not run draft SQL on production. Never embed `service_role` or secret keys in iOS/PWA.
2. On **staging only** use accounts A, B, C: A and B may message each other; C cannot read, update, send into, or enumerate A/B's conversations; guests/anonymous requests must not access private data.
3. Test sender impersonation, recipient read-only updates, forged Activity insert, blocked-user sends, cross-account reports, race/send-spam limits, RLS on all tables, and repeated auth switches.
4. Implement and test in-app **Block user** and **Report message/user** actions and a web-only owner moderation review workflow, including consequences for repeat abuse. The data tables alone do not complete these controls.
5. Implement trusted server-side Activity delivery. Do not permit client-created notifications or claim that an empty activity list is functional delivery.
6. Review error handling, unread aggregation at >500 messages, search privacy, pagination, reply notifications, and multiple-device syncing.
7. Obtain physical iPhone QA on both accounts before enabling the flag. Keep web-only Owner Panel Control, money and notification permission prompts unchanged.

## Independence from Live repairs

Safe Live/camera/gift/profile QA code remains in draft PR #85. **No file on the #85 repair branch was changed by this Inbox work.** Inbox is isolated in draft PR #81; no TestFlight config or backend migration was changed in this work. The existing `codemagic.yaml` diff in #81 predates these Inbox changes and needs its own owner scope review before any merge.
