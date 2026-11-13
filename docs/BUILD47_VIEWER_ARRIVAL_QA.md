# Build 47 native viewer entry notices — isolated fix

The host already has a real viewer sheet and connected participant count.
This fix adds a host-visible welcome chat entry on Stream roster arrival.

Rules:
- Only connected Stream participants, not client-sent chat claims.
- Ignore the host, empty IDs, duplicate records, and repeated snapshots.
- Prime the initial roster to avoid announcing people already connected.
- Suppress short (<30s) disconnect/reconnect duplicate joins; later reentry
  may be announced again. No new database rows or user tracking.
- Use the existing host-only chat list and original real viewer sheet.

Out of scope: Sleep Lives, Live Dashboard, Heart Me, Build 48 backend,
Build 49, iOS Liquid Glass and fake unread/visitor metrics.

Validation: local Flutter SDK unavailable. Widget/source tests committed
but not executed. iPhone + Android dual-device test required for first
join, exit, rejoin, co-host invite, chat/gift stress and reconnect.
No signed build or backend deployment. Review this branch before merging.
