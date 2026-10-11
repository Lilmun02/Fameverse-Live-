# Fameverse Law — Named Build Scope and Release Identity
**Status:** OWNER REQUESTED, awaiting review/merge. Issue: #70.
Applies to Fameverse Live native iOS/Android and PWA, with distinct release tracks.

## One update, one exact manifest
Every numbered build has exactly one *named* update, and its manifest lists the selected source fixes, their issues, actual merge SHAs, user-visible effect, test evidence and known blocked features. The update may contain multiple approved repairs, but none may be added silently. One root problem = one issue; one safe isolated patch = one branch and one draft PR; one regression law = one separate law/test contract; one release candidate = deliberate integration of reviewed patches.

No monolithic "everything" dev branch and no unwritten feature additions, unapproved assets, reworked gift audio, installation links, unapproved UI, payments, settings or workflow.

## Next proposed named update
**Fameverse Live — Live Stability & Gift Reliability**
- Candidate inputs only *after* review: #48 camera, #51 cohost geometry, #52 room refresh, #55 cohost audio (native only), #60 server-authoritative single gift event and queued playback, #62 approved watermark and no gift subtitles, #63 media/poster loading and #64 organized gift tray.
- Fameboard info #68 may follow independent testing. #69 UTC reset requires separately approved/staged SQL migration #49 first.
- PWA is a **separate delivery track**: audio repeat #61; web checkout #66; any PWA fix is not proof of a native TestFlight fix.
- Apple repeat purchase #65, Stripe checkout #66 and creator payout #67 are release blockers for advertising those money paths as working. They require separate sandbox proof; never silently skip or claim they passed.

## Release manifest required fields
Build name; exact platform and intended audience; version and build number; canonical source SHA; included issue/PR/commit manifest; excluded/deferred features with OPEN status; passed CI (full logs); failed gates; real owner/external device test ID; signing and upload source identity; external beta review/group assignment; known rollback/TestFlight prior build.

## Safe source and build
Existing `codemagic.yaml` `native-testflight` forces checkout of `integration/sep27-big-update` whatever branch triggers it. A QA branch trigger **does not** build that QA source. Never bypass source verification. Any proposed update to this workflow must be an independent owner-approved workflow change; none is authorized here.

Draft PRs do not make TestFlight builds. Source tests are not physical acceptance. Owner must explicitly approve integration, signed TestFlight upload and external tester expansion based on actual evidence. Keep last proven build available for rollback and do not grant developer agents authority to release or move money.

## Required gates
VERIFY → TRACE → isolated PATCH → TEST → REGRESSION LOCK → BUG SPRAY → real owner-device and external-device acceptance → explicit RELEASE approval. A failing required gate never becomes green through documentation changes.
