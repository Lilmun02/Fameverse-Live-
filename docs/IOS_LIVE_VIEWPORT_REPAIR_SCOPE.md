# iOS Live Viewport Repair Scope

Status: active repair candidate; physical acceptance required.

## Problem
The same production Live build renders with inconsistent vertical geometry between iOS and Android. iOS can place the Live shell and bottom controls against a viewport height that does not match the currently visible browser/PWA viewport.

## Authorized scope
- Live viewport sizing only.
- iOS/Safari/PWA safe-area and visible-viewport containment only.
- Preserve existing Live visual design, co-host geometry, chat, gifts, F menu, camera, microphone, WebRTC, and backend behavior.

## Acceptance
- Live shell fills the actually visible viewport on iOS and Android.
- Header remains inside the top safe area.
- Chat/composer/F menu remain inside the bottom safe area and do not drift when browser chrome changes.
- Existing two-square co-host layout contract remains unchanged.
- Automated gates must pass, followed by physical verification on the user's iOS and Android devices.

Do not call this repair fixed/ready/passed before physical acceptance.
