# Fameverse Engineering Safety Net

## Purpose

Fameverse is developed with AI assistance, but releases must be governed like a multi-person engineering team. Automation is a release gate, not proof that physical-device behavior is correct.

## Virtual engineering team

1. **Builder** — implements one scoped feature or fix on an isolated branch with small commits.
2. **Reviewer** — performs an independent review for race conditions, async cleanup, dead controls, duplicate state ownership, WebRTC/media risks, security boundaries, and scope creep before promotion.
3. **QA** — automated static checks, unit tests, Fameverse regression laws, production build, and browser smoke tests reject known-bad code automatically.
4. **Release engineer** — promotes only a tested commit SHA. Source/CI/deployment state must never be described as physical-device verification.

## Automatic gate

Every qualifying GitHub push runs the following sequence:

1. ESLint correctness checks.
2. TypeScript contract checking.
3. Vitest unit tests.
4. Existing Fameverse regression laws:
   - source line limits
   - Live presence
   - Tap Integrity
   - Verse Momentum contract
   - Live UX
   - Discovery UX
   - Live identity
   - co-host / gifter foundation
5. Vite production build.
6. Playwright mobile-browser smoke test.

The sequence fails fast. A failure in an early stage prevents later stages from being treated as a successful release candidate.

## Physical-device gate

Automation cannot prove hardware, operating-system, network, or acoustic behavior. Before a release involving those systems, use real phones to verify only the affected high-risk flows, including when relevant:

- iPhone/PWA startup and touch behavior
- camera and microphone permissions
- camera flip and camera recovery
- nearby-phone echo / acoustic feedback
- host/viewer WebRTC Live relay
- co-host connection and removal/leave behavior
- premium gift video and original audio playback
- 1x / 5x / 10x repeated gift playback
- PWA update/reopen behavior

A green GitHub gate means **source and automated verification passed**. It does not mean the feature is physically verified.

## Release rule

Build in small commits, combine them into one release candidate, run the complete automatic gate, deploy one preview, physically test the affected device flows, then promote the exact verified SHA to production.

If one feature fails physical testing, remove or repair only that feature's commit before production rather than hiding the failure or weakening a regression law.

## Gradual typing policy

Do not rewrite Fameverse into TypeScript all at once. Start with dangerous boundaries such as gift payloads, Live room identities, co-host signaling, WebRTC state, Supabase response shapes, and future wallet/earnings objects. Expand typed coverage only after each boundary is stable.

## Dependency policy

New dependencies must be added with exact versions. Existing runtime dependencies that currently use `latest` will be pinned in a separate, independently verified hardening commit so dependency freezing is not mixed with the first safety-gate rollout.

## Observability before external beta

Before the first external tester group, connect a runtime error-reporting service and tag reports with the release SHA/environment. Do not invent credentials or a DSN in source control. Runtime reporting complements, but does not replace, tester reproduction and physical QA.
