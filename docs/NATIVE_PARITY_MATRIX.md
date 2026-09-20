# Fameverse Native Parity Matrix

This matrix is the migration checklist from the current Fameverse web/PWA client to Flutter native. Update it with the exact PR/commit when a state changes.

Status values: NOT_STARTED, IN_PROGRESS, FIX_CANDIDATE, PHYSICAL_PASS, LOCKED, BLOCKED.

| Area | Native status | Automated gate | Physical QA | Notes |
| --- | --- | --- | --- | --- |
| Native project bootstrap | IN_PROGRESS | pending | n/a | Flutter/Codemagic foundation only; not product UI |
| Splash / startup | NOT_STARTED | required | required | Preserve backend update/release semantics where still relevant to native |
| Authentication | NOT_STARTED | required | required | Reuse authoritative Supabase auth contract |
| Home | NOT_STARTED | required | required | Redesign discussion/approval required before implementation |
| Discover | NOT_STARTED | required | required | Redesign discussion/approval required before implementation |
| Profile | NOT_STARTED | required | required | Redesign discussion/approval required before implementation |
| Viewer Live | NOT_STARTED | required | required | Device-sensitive |
| Host Live | NOT_STARTED | required | required | Device-sensitive |
| Front camera | NOT_STARTED | required | required | Native camera implementation, not Safari/WebKit |
| Rear camera | NOT_STARTED | required | required | Native camera implementation, not Safari/WebKit |
| Camera flip | NOT_STARTED | required | required | Must survive repeated front/back flips without geometry collapse |
| Camera off/on recovery | NOT_STARTED | required | required | Must recover without stale/blank/boxed preview |
| Microphone mute/unmute | NOT_STARTED | required | required | Device-sensitive |
| Comments | NOT_STARTED | required | required | Existing backend contract should be reused |
| FameTaps | NOT_STARTED | required | required | Preserve authoritative tap rules |
| Gift tray | NOT_STARTED | required | required | Custom gift artwork must match approved assets, no placeholder substitution |
| Gift send | NOT_STARTED | required | required | Backend-authoritative debit/event path |
| Premium cinematics | NOT_STARTED | required | required | Dragon/Phoenix media + audio physical QA |
| Co-host invite/accept | NOT_STARTED | required | 2-device required | Keep separate from camera-only acceptance |
| Co-host media/audio | NOT_STARTED | required | 2-device required | No echo/whistle/double-audio path |
| Wallet balance | NOT_STARTED | required | required | Test vs real money separation |
| Test-coin privileges | NOT_STARTED | required | required | Owner/admin only as approved; regular new accounts no seed |
| Self-gift restriction | NOT_STARTED | required | required | Temporary pre-payment-provider policy unless later explicitly changed |
| Real purchases | NOT_STARTED | required | required | Payment-provider design not yet approved |
| Creator earnings ledger | NOT_STARTED | required | required | Must be backend-authoritative before payouts |
| Real payouts | NOT_STARTED | required | required | Requires payment provider + audit/anti-abuse contract |
| Push notifications | NOT_STARTED | required | required | Later native feature |
| Deep links | NOT_STARTED | required | required | Later native feature |
| App Store/TestFlight signing | NOT_STARTED | signing gate | TestFlight install | Requires Apple account authorization/credentials |
| Google Play signing | NOT_STARTED | signing gate | Play internal test | Configure after Android release path is approved |

## Migration rule
A row may move to LOCKED only when its required automated and physical columns are satisfied for the exact native build. Do not inherit LOCKED status from the PWA automatically.