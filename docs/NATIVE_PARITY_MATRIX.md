# Fameverse Native Parity Matrix

This matrix is the migration checklist from the current Fameverse web/PWA client to Flutter native. Update it with the exact PR/commit when a state changes.

Status values: NOT_STARTED, IN_PROGRESS, FIX_CANDIDATE, PHYSICAL_PASS, LOCKED, BLOCKED.

| Area | Native status | Automated gate | Physical QA | Notes |
| --- | --- | --- | --- | --- |
| Native project bootstrap | PHYSICAL_PASS | passed | Build 13 installed | TestFlight/signing/publishing pipeline proved on a real iPhone; product parity is tracked separately below |
| Splash / startup | NOT_STARTED | required | required | Preserve backend update/release semantics where still relevant to native |
| Authentication | FIX_CANDIDATE | passed | required | Native Supabase sign-in/sign-up is wired to the authoritative Fameverse project; physical account QA still required |
| Home | FIX_CANDIDATE | passed | required | Ports the current production community/follow contract; no unapproved Home redesign |
| Discover | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Uses real profiles, follows, active live rooms, and tap totals; live room taps now open the native viewer transport |
| Profile | FIX_CANDIDATE | passed | required | Loads/saves real display name, username, and bio; avatar upload parity still pending |
| Viewer Live | IN_PROGRESS | source gate passed; full iOS preflight pending | 2-device required | LiveKit viewer room + remote video/audio subscription is wired; LiveKit Cloud credentials are still required before physical QA |
| Host Live | IN_PROGRESS | source gate passed; full iOS preflight pending | 2-device required | Creates authoritative Supabase live_rooms, requests host media token, publishes native camera/mic through LiveKit, heartbeats, and ends the room cleanly; LiveKit Cloud credentials are still required before physical QA |
| Front camera | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Uses native LiveKit/WebRTC capture on iPhone, not Safari/WebKit |
| Rear camera | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Uses native LiveKit/WebRTC capture on iPhone, not Safari/WebKit |
| Camera flip | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Native front/back track restart is wired; repeated physical flips required before FIX_CANDIDATE/LOCKED |
| Camera off/on recovery | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Native publish enable/disable is wired; physical QA required |
| Microphone mute/unmute | IN_PROGRESS | source gate passed; full iOS preflight pending | required | Native LiveKit microphone publishing and mute/unmute are wired; physical audio QA required |
| Comments | NOT_STARTED | required | required | Existing backend contract should be reused |
| FameTaps | NOT_STARTED | required | required | Preserve authoritative tap rules |
| Gift tray | NOT_STARTED | required | required | Custom gift artwork must match approved assets, no placeholder substitution |
| Gift send | NOT_STARTED | required | required | Backend-authoritative debit/event path |
| Premium cinematics | NOT_STARTED | required | required | Dragon/Phoenix media + audio physical QA |
| Co-host invite/accept | NOT_STARTED | required | 2-device required | Keep separate from base host-to-viewer Live acceptance |
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

## Native Live transport checkpoint

Native host-to-viewer media is now implemented in source on `native/flutter-v1`: Supabase remains authoritative for live-room presence and LiveKit is the native camera/microphone transport. The authenticated Supabase Edge Function `livekit-token` issues host/viewer-scoped media tokens and refuses host publishing privileges to non-host users.

The isolated Native Live repair gate passed engineering contract validation, Dart formatting, `flutter analyze`, and Flutter tests before pushing commit `92ee438dec4e002ad657a905fa2c63c01923ed92`. A fresh normal Native Preflight is required on the final branch head before moving these rows to FIX_CANDIDATE.

Runtime media remains blocked until the Fameverse LiveKit deployment supplies `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` to the Supabase Edge Function environment. Do not publish a tester TestFlight build until that dependency is configured and the full native preflight is green.

## Previous automated evidence

Native preflight run 35696192075 passed both jobs on the earlier product slice: YAML parsing, package resolution, engineering law, Dart formatting, static analysis, widget tests, bundle identifier verification, CocoaPods, unsigned Flutter iOS configuration, and unsigned Xcode Release compilation.

## Migration rule
A row may move to LOCKED only when its required automated and physical columns are satisfied for the exact native build. Do not inherit LOCKED status from the PWA automatically.
