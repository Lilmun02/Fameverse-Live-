# Fameverse Live Control + Backend Contract

Status: LOCKED for current beta unless the owner explicitly changes it.

## Live layout ownership

- Solo Live Layout V1 remains the approved full-screen/large host-video direction.
- FAM Co-host V1 remains two equal square camera panes side-by-side. Never revert to tall portrait strips.
- Solo and co-host use ONE Live control menu. Do not create a separate co-host control panel or nested control menu.
- Live screen is for viewing, chat and gifts. Creator-management/analytics/settings belong in Creator Studio.

## One Live control menu

The same host menu adapts to solo or co-host state and owns:
- invite a viewer/user to co-host;
- invite an eligible Live host to co-host;
- manage the current co-host;
- mute;
- remove/kick;
- ban;
- report;
- host Live controls already approved for the product.

Do not permanently place moderator assignment on the Live surface. When a viewer/user is opened from the Live roster/profile actions, the host may see Add as Mod when eligible.

## Moderator limit

- Beta/PWA: maximum 3 active moderators per creator.
- Native target: maximum 5 active moderators per creator unless the product owner/community later changes the limit through an approved decision.
- The limit must be enforced server-side, not only hidden/disabled in UI.

## Bottom interaction direction

The approved interaction order is:

Chat/composer -> Rose quick gift -> purple Fameverse gift box -> F menu

- Rose is the quick 1-coin gift.
- Purple gift box opens the full gift tray.
- Gift box includes the small Fameverse banner with a visible centered F.
- Send belongs inside the composer in the final Live Layout V1.

## Backend Authority Law

Every persistent, user-owned, creator, moderation, economy, social, discovery or network feature must have an explicit backend authority before it is called complete.

UI presence is not completion. Local React state or localStorage is not authoritative user/business data.

Client/device-only behavior may remain client-side when appropriate, including camera rendering, camera flip, microphone track controls, keyboard layout, PWA installation and visual animation. Those systems still require physical QA, but they do not require a database merely to exist.

For backend-owned systems, the server/database must validate permissions and important state transitions. The client may request an action; it must not be able to declare the authoritative result by itself.

## Current backend authority map

Already backed by Supabase:
- Auth/account identity
- Profiles and avatar storage
- Following/follower/friend relationship data
- Account roles foundation
- Live-room presence/history rows
- FameTap batch ledger/totals
- Gift wallet + append-only beta coin ledger
- Gift events
- Gifter stats + exact Lv.1-99 progression
- Beta feedback

Still requiring backend completion/wiring:
- Creator Studio persistent Live setup/drafts
- Creator Studio session history/analytics surfaces
- Persistent Live comments/moderation history
- Creator moderator assignments and 3-mod server limit
- Host-scoped kick/ban/mute/report enforcement
- Co-host moderation/state audit where persistence is required
- Clips media records/storage workflow
- Replay media records/storage workflow
- Creator earnings/payout accounting when real-money economy begins
- Admin/moderation control plane and audit log
- Realtime authorization hardening for protected Live actions

## Engineering laws

- Preview before visual commit.
- One conceptual commit at a time.
- Wire Law: if Fameverse presents it as a function, it shall function.
- Bug Spray: VERIFY -> TRACE -> SPRAY -> LOCK.
- CI pass is automated evidence only. Hardware/media/realtime behavior requires physical acceptance.
- Do not promote to release/production until the exact candidate is physically approved where required.
