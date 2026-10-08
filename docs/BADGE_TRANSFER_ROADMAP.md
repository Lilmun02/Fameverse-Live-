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
5. The Fameverse owner watches the recording, confirms the username and badge, and selects the Fameverse converted level based on the approved conversion policy. The owner can request more proof or reject a mismatch.
6. On explicit owner approval the secured backend atomically records the approved level in `badge_imports`. The app and website display **verified transferred recognition**.
7. Denied applicants can resubmit; reviewed claims retain their audit history. A user can have only one approved import.

**No automatic AI approval.** AI may help the owner inspect provided proof, but the owner is the final approver. A reviewer must not impersonate a source-app verification API.

## Badge conversion

Echo's algorithm is not known. An example of a transferred Level 15 becoming Level 20 does not establish a general formula. **Do not implement an unapproved +5 rule.** Owner supplies the precise level at review until a source-specific conversion table is explicitly approved.

Imported badge recognition is a separate data field from `gifter_stats`: **it does not award Fame Coins, increase purchased or gifted coins, create spending history, or create creator earnings.**

## Earnable and unlockable gifts

Fameverse can offer a curated set of gifts unlocked through **actual, verified on-platform activity**. A transferred badge does not unlock them automatically. Promotional and owner QA funds must not count as cash-backed spending.

Specific gift IDs, unlock thresholds, and whether eligibility is based on purchase or actual cash-backed gift sending **require owner approval before enabling any lock**. No existing gift is locked by this implementation.

## Release safety

The migration creates a private video-proof bucket and authenticated submission RPC. Only the verified owner role can run the review RPC and assign badge recognition. Reviewed source identity is unique across successful claims. The owner review panel must not block the rest of the web dashboard when the migration is not yet installed.

First Verse beta missions, account roles, payouts and earnings remain separate. Nothing in this feature may auto-approve First Verse or apply unverified badge levels to spending.
