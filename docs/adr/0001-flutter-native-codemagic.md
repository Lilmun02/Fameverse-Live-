# ADR-0001: Flutter Native + Codemagic CI

Status: Accepted for native bootstrap
Date: 2026-09-20

## Context
Fameverse currently has a web/PWA client. Live media behavior on iPhone has exposed browser/WebKit-specific failure modes. The project needs a native iOS/Android client without abandoning the existing backend contracts or engineering safety laws.

## Decision
- Build the native Fameverse client with Flutter/Dart.
- Keep the existing PWA operational during migration.
- Keep Supabase/backend contracts authoritative and shared where appropriate.
- Use GitHub as the source of truth for code, laws, parity state, and release evidence.
- Use Codemagic as the cloud Flutter build/test/sign/distribution system.
- Start with unsigned CI builds; enable Apple/Google signing only after account credentials and final identifiers are approved.
- Port features in vertical slices. Do not perform a blind all-at-once rewrite.

## Consequences
Benefits:
- Native camera/media APIs are no longer owned by Safari/WebKit.
- One Flutter client can target iOS and Android while allowing platform-specific code when needed.
- Cloud builds let the project advance while the owner is primarily working from a phone.
- Build and release policy can be enforced before TestFlight/Play distribution.

Costs/risks:
- Web and native clients coexist during migration and require parity tracking.
- Live/co-host behavior still requires careful native media architecture and physical device QA.
- Apple signing/App Store Connect and Google Play signing require account-level credentials/approval that cannot live in source control.

## Guardrail
This ADR does not declare existing PWA bugs fixed and does not approve any Home, Discover, or Profile redesign.