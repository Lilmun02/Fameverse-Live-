# Fameverse Badge Transfer — Build 33 candidate

Status: implementation staged on draft repair branch. **NOT activated on production, TestFlight, or the live database.** Approval, release, and device testing remain required.

## Supported sources

- TikTok
- Favorited
- EPIC

Echo is intentionally excluded. Imported levels do not stack across multiple source apps.

## Mobile submission and web moderation

1. From the **Fameverse mobile app**, open Creator Studio → Bring your badge.
2. Select exactly one supported source app. Enter the source username and badge number.
3. Record the **source-app profile, matching username and actual badge** together in one screen recording. Upload the video privately from the mobile app.
4. The submission is marked **pending**. It appears in the **web-only Owner Control Center** review queue.
5. The Fameverse owner watches the recording and confirms the username and badge. The owner sees the **proposed converted recognition level**, but cannot inflate it manually. The owner can request more proof or reject a mismatch.
6. On explicit owner approval the secured backend **calculates the capped level itself** and atomically records it in `badge_imports`. The app and website display **verified transferred recognition**, separate from locally earned level.
7. Denied applicants can resubmit; reviewed claims retain their audit history. A user can have only one approved import.

**No automatic AI approval.** AI may help the owner inspect provided proof, but the owner is the final approver. A reviewer must not impersonate a source-app verification API.

## Badge conversion

Echo's algorithm is not known. There is no verified cross-platform coin-to-level equivalence. The following is a **draft Fameverse incentive policy for owner approval**, not an Echo implementation or a claim of equivalent monetary spending:

```text
transfer_recognition_level = max(1, min(25, floor(source_badge_level * 0.4)))
```

There are **no base levels, added bonus points or +5 promotion** in this policy. Recognition alone never unlocks an earned Fameverse gifter badge or counts as local gifting. Source levels must be valid whole numbers. TikTok global gifter badges are limited to Levels 1–50 by this candidate, while Favorited and EPIC are restricted to 1–99 pending source-specific evidence. Examples: TikTok 1 → 1; TikTok 15 → 6; Favorited 38 → 15; EPIC 80 → 25. An account with no existing source-app gifter badge has nothing to transfer and starts with the normal Fameverse default level. **An alleged TikTok Level 80 is invalid.**

The backend—not the owner's browser—enforces the policy. The owner approves identity and evidence; the server computes the final level. Any attempted browser override is rejected. A future recalibration must be separately reviewed and tested.

Imported badge recognition is a separate data field from `gifter_stats`: **it does not award Fame Coins, increase purchased or gifted coins, create spending history, or create creator earnings.** Spending-gated gift unlocks must use only eligible, verified Fameverse spending and never `badge_imports.approved_level`.

## Earnable and unlockable gifts

Fameverse can offer a curated set of gifts unlocked through **actual, verified on-platform activity**. A transferred badge does not unlock them automatically. Promotional and owner QA funds must not count as cash-backed spending.

Specific gift IDs, unlock thresholds, and whether eligibility is based on purchase or actual cash-backed gift sending **require owner approval before enabling any lock**. No existing gift is locked by this implementation.

## Release safety

The migration creates a private video-proof bucket and authenticated submission RPC. Only the verified owner role can run the review RPC and assign badge recognition. Reviewed source identity is unique across successful claims. The owner review panel must not block the rest of the web dashboard when the migration is not yet installed.

First Verse beta missions, account roles, payouts and earnings remain separate. Nothing in this feature may auto-approve First Verse or apply unverified badge levels to spending.
