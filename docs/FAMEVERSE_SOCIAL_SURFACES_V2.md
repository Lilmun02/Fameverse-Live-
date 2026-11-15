# Fameverse Social Surfaces V2 — Locked Product Contract

Status: **LOCKED DESIGN DIRECTION / PHYSICAL QA REQUIRED**

This contract exists so Fameverse does not regress into generic admin panels, debug dashboards, giant empty cards, or duplicate navigation surfaces.

## 1. Home = algorithmic streaming surface

Home is the living, changing part of Fameverse.

Required hierarchy:
1. Fameverse top bar + current-user profile access.
2. **Live Now** creator row. Followed/friend creators rank first when they are live.
3. Three algorithm lanes: **For You / Following / Rising**.
4. Large Live recommendation cards with creator identity, Live state, FameTap signal, title, and a human-readable recommendation reason.
5. Recommended creators lower in the feed.

V1 ranking may use the data Fameverse actually has today: relationship signals, FameTaps/live engagement, follower counts, and a rising-creator fairness boost. Future watch-time/return/skip signals may be added only after those events exist authoritatively. Do not fake viewer-history signals before the backend records them.

Home must **not** revert to a friends/followers directory.

## 2. Discover = intentional exploration

Discover is not a duplicate Home feed.

Required hierarchy:
1. Search is prominent and purposeful.
2. Browse filters support **All / Live / Creators / Rising / Following**.
3. Live results use visual Live cards.
4. Creator results show identity, handle, follower context, bio where available, and a functional Follow action.
5. Search and filters must operate on real loaded creators/live rooms. Do not invent categories with no backend data.

## 3. Profile = social identity, not administration

The public profile should make the person the focus.

Required hierarchy:
1. Compact Fameverse header and Settings action.
2. Branded but compact hero treatment — no giant empty banner dominating the screen.
3. Large profile photo, public display name, public handle, public bio.
4. Followers / Following / Friends social stats.
5. Compact Edit Profile, Creator Studio, and Settings actions.
6. Creator Studio is a separate creator workspace, not the profile itself.

Forbidden on the public profile:
- Admin/owner role labels.
- OWNER QA or tester controls.
- Recharge/payment controls.
- Account email.
- Build/backend/update diagnostics.
- Payout moderation controls.

## 4. Edit Profile = full-screen consumer editor

Edit Profile must not appear as a giant rounded bottom-sheet/card floating over the Profile.

Required:
- Full-screen route.
- Profile photo and functional photo change action.
- Name, username, and bio fields grouped cleanly.
- Clear Save action.
- Internal owner/admin labels never seed or reappear as public bio content.

## 5. Settings = full-screen grouped settings experience

Settings must look like a real app settings screen, not a developer modal.

Required hierarchy:
1. Full-screen route with clear title.
2. Current profile summary at the top.
3. Profile section: username, name, bio, profile photo.
4. Creator section: Creator Studio.
5. Safety & Account section: Safety & legal and Sign out.
6. Legal/safety opens a dedicated full-screen policy center.

Do not add dead rows (language, agency, links, or other reference-app features) until Fameverse actually supports them.

## 6. Visual language

- Black base canvas.
- Fameverse violet/neon-purple as the primary accent.
- Red remains reserved for destructive/Live-ending state where appropriate.
- Use compact cards, clear spacing, strong typography hierarchy, and real creator content.
- Avoid oversized empty purple panels.
- Avoid stacking multiple phone-like rounded sheets inside one another.
- Reference screenshots may inform hierarchy and density, but Fameverse must remain visually distinct rather than copied.

## 7. Release law

Automated tests and compile success only mean **candidate-ready**. They never mean these surfaces are physically approved.

Physical iPhone behavior and screenshots outrank simulation. A mismatch between this contract and the installed candidate is a regression and the build remains failed until corrected.
