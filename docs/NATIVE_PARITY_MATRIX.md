# Fameverse Native Parity Matrix

This matrix is the migration checklist from the current Fameverse web/PWA client to Flutter native. Update it with the exact PR/commit when a state changes.

Status values: NOT_STARTED, IN_PROGRESS, FIX_CANDIDATE, PHYSICAL_PASS, LOCKED, BLOCKED.

| Area | Native status | Automated gate | Physical QA | Notes |
| --- | --- | --- | --- | --- |
| Native project bootstrap | PHYSICAL_PASS | passed | Build 13 installed | TestFlight/signing/publishing pipeline proved on a real iPhone; product parity is tracked separately below |
| Splash / startup | NOT_STARTED | required | required | Preserve backend update/release semantics where still relevant to native |
| Authentication | FIX_CANDIDATE | passed | required | Native Supabase sign-in/sign-up is wired to the authoritative Fameverse project; physical account QA still required |
| Home | FIX_CANDIDATE | passed | required | Ports the current production community/follow contract; no unapproved Home redesign |
| Discover | FIX_CANDIDATE | passed | required | Uses real profiles, follows, active live rooms, and tap totals; native viewer playback remains gated |
| Profile | FIX_CANDIDATE | passed | required | Loads/saves real display name, username, and bio; avatar upload parity still pending |
| Viewer Live | NOT_STARTED | required | required | Real active rooms can be discovered, but native media playback is intentionally not faked |
| Host Live | IN_PROGRESS | camera slice passed | required | Native camera preview slice only; broadcast transport/comments/gifts/cohost remain gated |
| Front camera | FIX_CANDIDATE | passed | required | Uses Flutter camera plugin / iPhone camera stack, not Safari/WebKit |
| Rear camera | FIX_CANDIDATE | passed | required | Uses Flutter camera plugin / iPhone camera stack, not Safari/WebKit |
| Camera flip | FIX_CANDIDATE | passed | required | Native front/back swap is wired; must survive repeated physical flips before LOCKED |
| Camera off/on recovery | FIX_CANDIDATE | passed | required | Native controller teardown/restart is wired; physical QA required |
| Microphone mute/unmute | NOT_STARTED | required | required | Device-sensitive; camera slice currently runs with audio disabled |
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
| App Store/TestFlight signing | PHYSICAL_PASS | passed | Build 13 installed | Direct manual signing + App Store Connect publishing succeeded; do not alter working secret/signing path without evidence |
| Google Play signing | NOT_STARTED | signing gate | Play internal test | Configure after Android release path is approved |

## Current automated evidence

Native preflight run 35696192075 passed both jobs on the product slice: YAML parsing, package resolution, engineering law, Dart formatting, static analysis, widget tests, bundle identifier verification, CocoaPods, unsigned Flutter iOS configuration, and unsigned Xcode Release compilation.

## Migration rule
A row may move to LOCKED only when its required automated and physical columns are satisfied for the exact native build. Do not inherit LOCKED status from the PWA automatically.
