# Build 47 native integration review gate — November 13, 2026

**Review branch only. This is NOT a new TestFlight build, not a merge,
and not permission to change workflows, signing, backend data or funds.**

## Source candidate assembled from isolated draft PRs

- #113: native Owner Center removed from route; privileged panel stays web-only
- #114: opt-in pre-Live camera preview and cleanup
- #115: host/viewer keyboard-safe chat layouts
- #116: gift combo FIFO, exact final combined receipt and callback serial locks
- #119: camera-flip profile-photo fallback for host and cohost
- #120: swipeable, real full-screen Stream Video Live Feed
- #121: account-scoped, read-only system Inbox and policy reminders
- #124: real Stream viewer arrival messages visible to the host

All source PRs remain draft and unmerged. Integration code is a
candidate for native/physical regression QA only. The integration
branch was created from the exact Build47 source, and code was
transplanted without merging PRs or changing the release branch.

## What was verified in this session

- GitHub readback: 24 intended files; 0 commits behind the Build47
  baseline; no changes outside native/flutter_v1 and docs.
- The three overlap-heavy files (shell/host/viewer) combined with no
  textual patch conflict. This is NOT compilation or behavioral proof.
- Source assertions found expected Inbox, feed, gift, camera fallback,
  keyboard, Web-only owner and host join behaviors. Native and browser
  QA remain unrun.
- No Codemagic build, Flutter analyze/test, unsigned iOS/Android
  platform build, physical device test, App Store review or signed IPA.

## Critical TestFlight source guard conflict — MUST NOT BYPASS

The existing `codemagic.yaml` native-testflight verification still
greps for `Build23OwnerControlCenterScreen` in
`fameverse_shell_build23.dart`. This candidate intentionally removes
that privileged route in accordance with the owner's Web-only rule.
**The current workflow will block a TestFlight run from this candidate.**
Do not insert a fake source string or secretly weaken the guard.
The owner must approve the *exact* workflow change separately, after
the candidate passes other native regression checks.

## Remaining launch blockers / separate work

1. Flutter SDK is unavailable in this environment. The source has
   not been formatted/compiled/analyzed or run on iOS/Android.
2. Multi-device host/cohost/video/gift/combo/keyboard stress tests
   still require real signed builds and explicit owner approval.
3. Production Daily/Weekly UTC ranking backend migration remains
   unapplied; native Daily/Weekly labels cannot be certified yet.
4. Real viewer count for Discover is NOT in the current
   `get_active_live_rooms_v2` response. Do not show Fame Taps as
   a verified viewer count or fabricate participant totals.
5. Current Inbox is **system updates only**, not direct messaging,
   recipient notification storage or unread receipt support.
6. Eight-second blurred outsider previews and 18+ Live selection
   have not been finished or QA-proven.
7. Production coin-purchase policy enforcement and all financial
   payout workflows remain outside this native integration.
8. Build48 backend patches, Build49 Heart Me, future Live Dashboard,
   Sleep Lives and iOS27 Liquid Glass are NOT in this branch.

## Owner approvals remain independent

No action on this branch authorizes merging any PR, modifying
`codemagic.yaml`, applying migration/RLS, deploying Supabase/Stream
or Vercel, changing signing, starting CodeMagic, uploading to TestFlight,
or distributing to internal/external testers. Request exact approvals
with commit SHA and test evidence once all blocking checks are addressed.
