# Build 18 Physical Acceptance Matrix

Build 18 remains **RED** until every required row is confirmed on physical iPhones.

| Path | Test | Required result |
| --- | --- | --- |
| Owner | Start Live as host | Full creator handle is visible without `...`; LIVE badge, viewer count, Fame Taps and End remain readable |
| Owner | Host control row | End remains a red destructive action; the Fame control is visibly purple and recognizable, not a blank pale circle |
| Owner | Camera off | The participant stays visually present with their profile photo (or Fameverse fallback), name and a subtle Camera off state; never a black empty box |
| Owner | Join another user's Live as viewer | Live loads; handle, LIVE status, viewers and Fame Taps are readable |
| Owner | Type a chat message | Text wraps visibly to additional lines in the composer instead of disappearing across one single line; composer grows up to 3 lines |
| Owner | Read Live chat | Chat uses the V2 hierarchy: readable avatar/initial, creator/viewer name, level badge when applicable, then a clearly separated message; no tiny debug-log look |
| Owner | Co-host chat placement | With two cameras active, chat begins directly below the equal square camera row instead of leaving a giant empty purple gap |
| Owner | Tap rapidly | Fame Tap total rises and visible purple `F` / flame particles rise from the lower-right |
| Owner | Open Gifts | Gift button is visible; tray opens; no black/empty premium thumbnails |
| Owner | +10K test coins | Balance changes while the tray is still open |
| Owner | Send 1-coin classic gift | Chat/activity records it without a premium full-screen takeover |
| Owner | Send each premium gift | Tray responds immediately; animation appears; audio is present and clearly audible |
| Owner | Become co-host | Host/co-host cameras are equal square boxes side-by-side; no full-width stacked `You` panel |
| Owner | Premium gift while co-hosting | Animation and audio remain usable while microphone/camera are active |
| Owner | Leave live while co-hosting | Back/leave exits the Live screen; cleanup cannot trap the route |
| Owner | Host ends live | Co-host/viewer exits Live automatically |
| Tester | Host a Live on external TestFlight build | Full handle is visible; End/F controls are readable; chat is organized/readable; co-host stage does not stack vertically |
| Tester | Camera off while hosting/co-hosting | Their profile photo/fallback remains in the camera square with Camera off state |
| Tester | Join Live on external TestFlight build | Normal viewer UI appears; no owner/admin QA UI |
| Tester | Bottom interaction row as viewer | Comment, Send, Gift and F actions fit; Gift cannot disappear on narrower iPhone widths |
| Tester | Composer | Typed text wraps and remains visible for 1–3 lines before internal scrolling |
| Tester | Chat | Normal reading size and organized V2 layout; not the tiny Build 16 presentation |
| Tester | Gifts | Store opens, gift visuals are clean, send works, wallet/activity agree |
| Tester | Host ends live | Tester is ejected from the Live screen automatically |

The screenshot with a visible red **End** button is a **host-side** screenshot. A missing Gift button in that specific host view is not evidence of the viewer Gift bug because hosts cannot gift their own Live. The viewer Gift-button check remains separately required above.

Automated CI is a blocker only. It is not proof that these physical tests passed.
