# Fameverse internal TestFlight QA — Live, Gifts, and Badges

**Candidate branch:** `qa/native-live-gifts-badges-oct14` (draft PR #85).  
**Scope:** QA only. No external TestFlight promotion, production DB changes, or merge without founder approval.

## Included in this candidate

- Verse Pioneer recognition on own and public profiles, server-award gated; own/public refresh and stale-request protection (PR #84).
- FIRST VERSE earned-only badge on own profile; no level, coin, or badge awarded by client (PR #84).
- Host and cohost camera-power operations serialized with lens flips; two cohost video boxes separated by 2 px (PR #59).
- Live rooms refreshed independently on Home/Discover at most one request at a time, every 20 seconds while those tabs are active; timer disposed with shell (PR #59).
- Gifts below 100 coins show a compact 56 × 48 symbol at mid-left, without a video player; premium gifts retain their normal presentation (PR #77).
- Gift receipt IDs deduplicated on host and viewer, preserving distinct combo receipts; owner-host QA overlay avoids local double audio (PR #78).

## Explicitly **not** included

- Inbox backend and message delivery: database table and secure policies not rolled out.
- Bring Your Badge submissions/approvals: secure request table and web-only review not rolled out.
- Held notification-permission or UTC-calendar reset changes.
- Standalone web password-reset PR, other unreviewed changes.

## Unfinished founder requirements — do not claim these have shipped

The Live and gift changes above are **candidates**; the video recorded on October 14 shows a failed Live join and profile-detail refresh. Server logs from the same evening contain both successful Stream token issuance and `room-not-live` responses. This is not proof that video join, latency, or uptime is fixed.

- **Critical live acceptance:** host goes live first, viewer can actually join and see/hear the host, uptime survives a long session, host/cohost camera flip and off/on stay usable, leaving removes stale sessions, and failed joins do not allow fake comments/taps/gifts.
- **High-volume gifting:** three distinct gifts in 5× combos during one Live; each authorized send must produce exactly the intended debit, quantity, chat receipt, and audience playback. Verify 1- and 100+-coin audio rules, premium media timing, no flicker/double sound, and no orphaned visuals. Automated dedupe checks alone are insufficient.
- **Chat and navigation:** spam comments across two phones, open/close Live and profiles repeatedly, evaluate Home/Discover load/swipe responsiveness and profile image update. Native live-to-live vertical swiping and watch-while-hosting/multi-guest support are not confirmed in this candidate.
- **Gift assets:** founder-approved cinematic Dragon/Phoenix art and sound must be verified as real assets, never placeholder emoji or rejected previews.
- **Business systems:** Apple sandbox in-app coin purchases, web checkout, provider payouts, creator split, and owner promotional testing balances remain unverified in this candidate. Do not claim payment certification.
- **Pending product features:** secure Inbox messaging delivery, TikTok/Favorited/EPIC badge transfers with WEB-only owner review, verification review, affiliate/subscription workflows, and invite-only referral acceptance require dedicated complete implementations and QA. They are not silently included here.
- **Founder control contract:** Owner Panel Control belongs on the web; mobile profile settings are separate. Audit any legacy native owner-panel route before a full product release rather than silently shipping it as approved.
- **Other held work:** notification permission and UTC reset changes stay out until their hold is lifted. First Verse earned state must never grant free levels or coins.

**Do not promote to external testers or a public release because this list exists.** A missing item remains open until real code, backend permission rules, and physical acceptance establish it works.

## Build provenance, automated checks, and release boundaries

1. Confirm GitHub quality preflight passes (Dart formatting, Flutter analysis, Flutter tests, native source contract).
2. Confirm unsigned iOS and Android preflight builds pass.
3. Start only the **existing** `native-testflight` Codemagic workflow for the exact branch above after explicit authorization. Never substitute integration or the older badge-only branch.
4. Save signed IPA source commit and `build32_source_identity.txt`; compare against the GitHub head at the time the build was queued. A green GitHub Action **does not** mean Apple has received an IPA.
5. Record TestFlight build number, processing completion, bundle ID `com.fameverse.live`, and the actual installed iPhone build version.
6. Keep the physical iPhone release gate red until founder confirms the full below matrix. Identify the last working TestFlight build as rollback before releasing any candidate.

## Physical-device acceptance matrix (founder + second tester)

| Scenario | Required outcome |
| --- | --- |
| Founder own profile | `VERSE PIONEER` appears for awarded account; disappears for unawarded account; revisiting profile refreshes correctly |
| Public profile | Awarded user's `VERSE PIONEER` appears; pull to refresh reloads the award; no recognition on unawarded profile |
| First Verse incomplete | Locked, not displayed as earned; no free levels/coins |
| First Verse complete | `FIRST VERSE` appears after backend-confirmed earned state; no local-only grant |
| Host camera | Repeated front → back → front flips; camera off → on → flip; no black screen/crash |
| Cohost camera | Same camera and lens stress steps on second iPhone; two video boxes remain side by side |
| Live discovery | Host goes live; second account sees room on Home/Discover without app restart; leaving removes stale room; brief network failure keeps UI usable |
| Low-value gift | Under-100 gift shows small mid-left symbol; no gift video/audio; chat entry appears |
| Premium gift | One purchased gift shows legitimate full media and sound once; wallet/backend debit and recipient event match |
| Combo gift | 5× combo shows correct count, one authoritative chat/receipt per send, no duplicate sounds or crash |
| Owner QA gift | Owner-host gift displays one local audible/visual instance; other participants receive the gift normally |
| Two-phone session | Host and viewer join/leave, chat, gifts, and cohost clean up without rendering leaks or unexpected camera shutdown |

**Known risks:** Codemagic queue/signing, TestFlight Apple processing, backend/network availability, gift audiovisual behavior, and device-specific Stream Video interactions require real-device verification. Neither repository tests nor an unsigned build proves these cases.

**Acceptance:** Founder tests internal TestFlight first; only after explicit acceptance should external testers be invited or updated.
