# Fameverse Physical Acceptance Law

Status: enforced for release candidates.

## Core law
A feature that depends on real camera, microphone, realtime networking, multiple devices, payments, or other hardware/runtime behavior is **not release-ready because CI passes**.

It must pass both:

1. Automated engineering gates on the exact code path.
2. Physical acceptance on the real target devices and workflow.

## Functional law
If Fameverse presents a control or behavior as a function, that function shall work end to end. A rendered button, connected socket, successful build, or passing static assertion is not enough by itself.

## Co-host release lock
Co-host may not be promoted to `beta/vercel-ready` or a `release/**` branch until the physical acceptance manifest records a pass for the current co-host code fingerprint.

Required physical checks:

- Host can invite and viewer can accept.
- Both real cameras remain connected.
- Host and co-host panes preserve the approved bounded portrait geometry; no full-height 50% strips.
- Two-way audio is usable without repeating echo, feedback, or whistle.
- Either side can leave/end co-host and camera/microphone resources clean up correctly.

Any change to a critical co-host file changes the fingerprint and automatically invalidates the previous physical approval. The feature must be tested again before release.

## Status language
Before physical acceptance, use terms such as `code-complete`, `preview-ready`, or `awaiting physical acceptance`. Do not call the feature `ready`, `fixed`, or `passed` until the physical test has actually passed.
