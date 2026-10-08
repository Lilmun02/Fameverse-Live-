# Fameverse Build 33 — Existing TestFlight Workflow

**Status:** GitHub native preflight passed; Codemagic signing and Apple processing still require confirmation.
**Branch:** `qa/build33-private-iphone-oct07`
**Existing Codemagic workflow:** `native-testflight` — Fameverse Native TestFlight Candidate.
**Bundle:** `com.fameverse.live`.

Build 33 uses the original Codemagic → App Store Connect → TestFlight path.
It does not use Ad Hoc, device UDIDs, a downloadable installation link, or an alternate workflow.
In this QA branch only, the original workflow is pinned to the Build 33 QA source. It refuses to run when the selected Codemagic branch is not `qa/build33-private-iphone-oct07`.

To build, select the QA branch and **Fameverse Native TestFlight Candidate** (workflow ID `native-testflight`) in Codemagic. Verify that its logs show **Checkout locked Build 33 QA source**, then require a successful IPA signing and App Store Connect upload before claiming TestFlight availability.

This does not modify `main`, the Build 32 integration branch, live payments, database migrations or native product features. It does not authorize external TestFlight review or App Store submission. Physical iPhone IAP sandbox tests are still required.
