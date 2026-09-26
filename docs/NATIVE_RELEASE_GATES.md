# Fameverse Native Release Gates

These gates apply to Flutter native work. They supplement docs/ENGINEERING_CONSTITUTION.md.

## Gate N0 — Scope approved
Required before code:
- branch purpose documented
- in-scope and protected systems identified
- visible redesigns explicitly approved
- backend migrations identified when applicable

## Gate N1 — Static quality
Required on every native candidate:
- `dart format --set-exit-if-changed`
- `flutter analyze`
- no committed secrets
- no TODO pretending to be a working feature

## Gate N2 — Automated behavior
Required before device QA:
- `flutter test`
- relevant unit/widget tests
- repository regression laws for the feature being changed
- backend contract tests when backend behavior changes

## Gate N3 — Platform build
Required before release candidate:
- Android build succeeds
- iOS build succeeds
- unsigned iOS build is acceptable only before signing/distribution is enabled
- once signing is enabled, the signed build must also pass

## Gate N4 — Integration
Required for backend-connected features:
- staging/test backend call succeeds
- authorization/RLS behavior verified
- failure state is handled
- no frontend-only enforcement for money/roles/permissions

## Gate N5 — Physical acceptance
Required for device-sensitive work:
- exact commit/build recorded
- exact device/scenario recorded
- required sequence completes without the reported failure
- repeated actions tested when the bug is intermittent

Examples:
- camera flip: front -> back -> front repeatedly
- camera recovery: on -> off -> on
- premium gift: tray art -> send -> debit -> event -> cinematic -> audio
- co-host: invite -> accept -> dual media -> audio -> leave cleanup on two devices

## Gate N6 — Release candidate
Required before TestFlight/Play candidate:
- all required N0–N5 gates green
- changelog entry
- rollback build identified
- version/build number unique
- unresolved known issues listed explicitly

## Gate N7 — Distribution
Required before external release:
- Apple/Google signing configured securely
- store metadata/privacy requirements satisfied
- crash/error monitoring plan active
- production backend configuration verified

## Status rule
CI can promote OPEN -> FIX_CANDIDATE. Only required physical acceptance can promote FIX_CANDIDATE -> LOCKED.

## Failure rule
A red gate stops promotion. Fix the cause or document why the gate is not applicable. Do not delete, weaken, or bypass a valid gate simply to make a build green.