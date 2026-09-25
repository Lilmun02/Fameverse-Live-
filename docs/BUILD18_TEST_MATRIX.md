# Build 18 Physical Acceptance Matrix

Build 18 remains **RED** until every required row is confirmed on physical iPhones.

| Path | Test | Required result |
| --- | --- | --- |
| Owner | Join another user's Live as viewer | Live loads; handle, LIVE status, viewers and Fame Taps are readable |
| Owner | Tap rapidly | Fame Tap total rises and visible `F` / flame particles rise from the lower-right |
| Owner | Open Gifts | Gift button is visible; tray opens; no black/empty premium thumbnails |
| Owner | +10K test coins | Balance changes while the tray is still open |
| Owner | Send 1-coin classic gift | Chat/activity records it without a premium full-screen takeover |
| Owner | Send each premium gift | Tray responds immediately; animation appears; audio is present and clearly audible |
| Owner | Become co-host | Host/co-host cameras are equal square boxes side-by-side |
| Owner | Premium gift while co-hosting | Animation and audio remain usable while microphone/camera are active |
| Owner | Leave live while co-hosting | Back/leave exits the Live screen; cleanup cannot trap the route |
| Owner | Host ends live | Co-host/viewer exits Live automatically |
| Tester | Join Live on external TestFlight build | Normal viewer UI appears; no owner/admin QA UI |
| Tester | Bottom interaction row | Comment, Send, Gift and F actions fit; Gift cannot disappear on narrower iPhone widths |
| Tester | Chat | Normal reading size; not the tiny Build 16 presentation |
| Tester | Gifts | Store opens, gift visuals are clean, send works, wallet/activity agree |
| Tester | Host ends live | Tester is ejected from the Live screen automatically |

Automated CI is a blocker only. It is not proof that these physical tests passed.
