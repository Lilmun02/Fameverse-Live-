# Fameverse Native Bootstrap

This directory is the Flutter-native migration target for Fameverse.

## Current state
This is intentionally a pipeline probe, not approved product UI. It exists to prove that GitHub -> Codemagic -> Flutter analyze/test/build works before product features are ported.

## Rules
- Follow `../../docs/ENGINEERING_CONSTITUTION.md`.
- Update `../../docs/NATIVE_PARITY_MATRIX.md` as features move through native states.
- Do not copy PWA bugs into Flutter simply to preserve implementation parity.
- Do not redesign approved Fameverse product surfaces without explicit approval.
- Do not add App Store/Play secrets to source control.

## Local/CI bootstrap
The committed Dart project is minimal. Codemagic generates missing iOS/Android platform scaffolding in its ephemeral workspace using `flutter create`, then runs format/analyze/test and unsigned platform builds.

Before the first signed/TestFlight build, platform folders, final bundle identifiers, signing settings, app icons, and store configuration must be reviewed and locked.