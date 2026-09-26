# Next TestFlight candidate

This file freezes the exact product surface to be verified before the next native TestFlight upload. The App Store/TestFlight build number is assigned externally and is not inferred from the internal branch name.

## Required product state

- Live V2 remains the visual authority for solo and co-host Live.
- Co-host cameras are two equal square tiles side by side.
- Home is the algorithmic Live feed; Discover is intentional exploration/search.
- Profile and Settings use the redesigned consumer-facing full-screen surfaces.
- Existing users land on Sign in and can authenticate with their existing email/password.
- Go Live has no wishlist selector.
- Ending Live clears the saved title/goal so the next setup starts clean.
- Fame Coin recharge exposes exactly three fixed packs: 100 / 1,000 / 5,000, plus custom amount.
- Recharge remains PayPal-first. Stripe is deferred until at least 500 active users and explicit CEO approval.

## Release law

Automated formatting, static analysis, unit/widget tests, and unsigned native compilation must be green before generating a new TestFlight candidate. TestFlight upload is not a physical PASS. Physical approval remains required on the exact installed candidate before tester-wide release.
