# Fameverse Contributor Workflow

Before changing code, read this file and `docs/ENGINEERING_CONSTITUTION.md`.

## Owner approval is required

No pull request, merge, release, TestFlight candidate, database migration, payment change, Live media change, or regression-law change is considered approved until the product owner explicitly approves it.

## Working law

1. Reproduce the bug before editing when possible.
2. Patch the bug itself. A regression test does not count as the patch.
3. Preserve working behavior outside the approved scope.
4. Run the relevant static analysis, tests, and regression checks.
5. For device-sensitive behavior, code/CI success is only a FIX_CANDIDATE. Physical-device testing is required before PASS.
6. Add or update a regression lock only after the patch exists.
7. Never mark a bug fixed, passed, or locked without evidence.
8. Never silently replace approved UI, flows, providers, payment behavior, or product decisions.
9. Never merge directly to the protected product branch for bug work. Use a dedicated branch and pull request.
10. The product owner makes the final merge/release decision.

## Current high-risk systems

Treat these as regression-sensitive and isolate changes carefully:

- Stream Video Live/co-host media, camera flip, mute/camera state, leave/end behavior.
- Live comments, keyboard/focus behavior, gift activity, gift animations, combo quantities, and gift tray.
- Profile identity, verification state, owner-only controls, Creator Studio, and Settings.
- Live Feed / Story Feed navigation and Stories.
- Startup splash and backend update notices.
- Fame Coin funding, promotional/test coins, cash-backed coins, creator earnings, payout liabilities, and owner reserve accounting.
- TestFlight/Codemagic source locking and build identity.

## Money law

- Testing/promotional coins must never create withdrawable creator earnings.
- Cash-backed coins and promotional liabilities must remain explicitly separated.
- Owner/admin normal QA gifting must remain promo-only.
- Any real cash-backed reward must use the explicit funded-reserve path.
- Never change payout, fee, split, or reserve logic as a side effect of unrelated work.

## Pull request requirements

Every pull request must state:

- Bug or feature being changed.
- Reproduction evidence or approved product requirement.
- Root cause.
- Exact files/systems changed.
- What was intentionally not changed.
- Tests/checks run.
- Remaining device/manual QA.
- Regression lock added or updated, if applicable.
- Known risks.

Do not merge your own pull request without owner approval.
