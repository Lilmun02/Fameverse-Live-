# Future release: iOS 27 Liquid Glass (isolated candidate)

Not included in Build 47 or current TestFlight. This native iOS
visual enhancement starts from the Build 47 baseline. No CI, signing,
web, Android visual changes, payment or production data changes.

## Implemented
- Native Apple UIKit tab bar via the pinned real_liquid_glass 0.3.0 plugin.
- Same Home, Discover, Live, Profile selection index and callbacks.
- A restrained Fameverse purple selection tint and native material.
- Older iOS gets system fallback from the native plugin.
- Android and web preserve original Material NavigationBar.
- Live camera setup (tab 2) deliberately keeps existing navigation until
  native platform-view/Stream compositing passes on a real iPhone.

## Critical unverified prerequisites
- Existing pubspec.lock was not regenerated here; Flutter and Dart are
  unavailable in this execution environment. Run flutter pub get and
  commit the generated lockfile before integrating any release.
- Current stable Flutter / Dart SDK must satisfy plugin Dart >=3.12.1;
  the iOS plugin requires an Xcode 26+ SDK (Xcode 27 for latest iOS27).
- Do not silently alter Codemagic, platform shell generation, signing,
  bundle ID, branches or TestFlight workflows to satisfy this package.

## QA before CEO review for future update
1. Resolve Flutter dependencies, commit generated lockfile, format, analyze,
   Flutter full test suite, Android debug and unsigned iOS builds.
2. On iOS27: native glass appearance, selected states, VoiceOver, Reduce
   Transparency, Increase Contrast, back navigation and safe-area spacing.
3. Older supported iOS: native fallback; Android: unchanged Material nav.
4. Two-device Live, co-host, gift queue, camera flips, chat keyboard and
   foreground/background performance to catch native overlay regressions.

Do not merge with the Build47 release candidate. This is a design
candidate only; no device tests or signed build have passed.
Rollback is to close/revert the isolated branch; original app is intact.
