# Fameverse Engineering Constitution

This file is a release law, not a suggestion. Fameverse code, tests, reviews, automation, and release decisions must follow it.

## 1. Project identity
- This repository is Fameverse only. Never mix AIWCORE, Zenith Drift, Roblox, Recon, or unrelated projects into Fameverse work.
- Web/PWA and Flutter native may share backend contracts, but they are separate clients. A repair to one client must not silently rewrite the other.

## 2. Source-of-truth order
When evidence conflicts, use this order:
1. Explicit user approval or rejection.
2. Physical-device behavior on the exact tested build.
3. Reproducible automated tests and logs.
4. Repository documentation and contracts.
5. Assumptions.

No simulator, browser smoke test, unit test, or CSS inspection may overrule a physical failure.

## 3. Bug states
Every tracked bug uses one of these states:
- OPEN: reproducible failure, root cause unknown or repair not ready.
- FIX_CANDIDATE: repair exists and automated gates pass, but required physical QA has not passed.
- LOCKED: exact repair commit passed required automated and physical QA and has a regression guard.
- REOPENED: a previously locked failure has returned.

Never call a bug fixed when it is only a FIX_CANDIDATE.

## 4. Verify -> Trace -> Spray -> Lock
For every bug:
1. VERIFY the actual failure and exact device/build.
2. TRACE the root cause before changing code.
3. SPRAY the smallest isolated repair.
4. Add or strengthen a regression law.
5. Run automated gates.
6. Run required physical QA.
7. LOCK only after all required evidence passes.

## 5. Scope isolation
- One subsystem or approved feature per repair branch unless dependencies require otherwise.
- State explicitly what a PR may touch and what it must not touch.
- Never bundle unrelated visual redesign, backend policy, wallet logic, Live media, or profile work into one repair.
- Do not merge a branch only because unrelated checks are green.

## 6. Approved UI is locked
- Do not redesign approved UI without explicit approval.
- Bug repair must preserve approved geometry, controls, labels, and interaction patterns unless the bug itself requires changing them.
- New visible controls require approval before production.
- Dead buttons are prohibited. If a control is visible, its intended action must be wired or the control must not ship.

## 7. Backend authority
- Money, gifts, payouts, permissions, roles, balances, and other trust-sensitive decisions must be authoritative on the backend.
- Frontend checks may improve UX but must never be the only enforcement.
- Schema/RPC changes require migration files and regression coverage.
- Production backend and repository migrations must never intentionally drift.

## 8. Native parity law
- Flutter is a migration, not permission to drop existing approved behavior.
- Every migrated feature must be tracked in docs/NATIVE_PARITY_MATRIX.md.
- A feature is not native-complete until logic, UI, automated tests, and required physical QA are accounted for.
- Native-specific architecture may differ when it improves reliability, but user-facing behavior stays approved unless explicitly redesigned.

## 9. CI law
A candidate may not advance when a required gate is red. Native CI must cover, at minimum:
- formatting/static analysis
- unit/widget tests
- architecture/regression laws
- Android build
- iOS build
- release-specific signing checks when distribution is enabled

CI success does not equal physical acceptance.

## 10. Physical-device law
- Physical device behavior outranks simulation.
- Live camera, microphone, audio routing, media playback, co-host, gifts, background/foreground recovery, and any device-sensitive feature require physical QA when changed.
- Evidence must identify the commit/build tested.
- Passing one scenario does not pass a different scenario. Example: camera flip acceptance does not pass co-host audio acceptance.

## 11. Money and payout law
- Test coins and real money are separate concepts.
- No test balance may be mistaken for a payable balance.
- Real payout work requires backend ledger authority, anti-self-dealing controls, transaction auditability, and explicit payment-provider integration.
- No payout feature may be called production-ready from UI-only testing.

## 12. Security and secrets
- Never commit passwords, private keys, App Store Connect .p8 files, signing certificates, service-role keys, or production secrets.
- Secrets belong in approved secret stores such as Codemagic environment groups/provider integrations.
- Public client keys must still be limited by backend authorization/RLS.

## 13. PR contract
Every substantial PR must state:
- scope
- protected/out-of-scope systems
- root cause or feature contract
- files/systems changed
- tests/laws added or updated
- automated verification result
- physical QA required
- rollback path
- release state

## 14. No fake completion
- Never say fixed, working, deployed, locked, or released without evidence for that exact claim.
- If evidence is incomplete, say exactly what remains unverified.
- A failed test is information, not permission to weaken the law merely to make CI green.

## 15. Rollback discipline
- Every production/native release candidate must be traceable to a commit/tag/build.
- Keep previous known-good release available until the new candidate passes required physical acceptance.
- If a new repair causes a regression, stop, isolate, and revert or repair; do not stack guesses.

This Constitution applies to both human and AI-assisted development on Fameverse.