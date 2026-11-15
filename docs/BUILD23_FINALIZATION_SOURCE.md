# Build 23 finalization source marker

This marker exists to force a fresh Native Preflight against the persisted stabilization source after the Build 23 patch workflow has written its verified fixes back to `integration/sep27-big-update`.

It is **not** a physical-device PASS or a public-release approval.

The exact persisted source now includes:
- serialized host camera flip protection;
- serialized co-host camera flip protection;
- Live gift queue/combo rendering guards already covered by the stabilization suite;
- whole-card Fame Coins store access while preserving the dedicated Buy and Refresh controls;
- the existing startup, identity, keyboard, verification, gifting, owner-control, payment-isolation and performance regression guards.

Release acceptance still requires the owner iPhone and external tester device gates defined by the repository laws.
