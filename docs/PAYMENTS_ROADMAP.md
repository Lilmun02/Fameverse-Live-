# Fameverse Payments Rollout

## Current Build 23 candidate

Fameverse is a multiprocessor product. Existing payment paths remain isolated and must not silently replace one another:

- Apple IAP remains available for approved iOS Fame Coin purchases.
- PayPal recharge remains a separate native/backend path where it is intentionally exposed.
- Stripe is approved for Fame Coin purchases through Stripe-hosted Checkout using an app-to-web flow.

## Stripe Checkout approval — October 1, 2026

The previous 500-active-user Stripe gate is superseded by explicit CEO approval on October 1, 2026 after the Fameverse Stripe business account reached payment-ready status.

Approved Stripe rollout contract:

- Use Stripe-hosted Checkout. Do not collect card numbers inside Fameverse.
- The authenticated Fameverse backend creates Checkout Sessions.
- The client sends only an approved Fame Coin pack identifier; it never chooses or sends the authoritative cash price.
- Pack price, coin quantity, currency, and Stripe Price ID are server-authoritative.
- Test and live Stripe keys, Price IDs, and webhook signing secrets stay separated.
- Fame Coins are credited only after a signed Stripe webhook confirms a paid Checkout Session.
- A browser success/return page never credits coins.
- Stripe webhook fulfillment must reuse the authoritative Fameverse purchase/recharge ledger and remain idempotent.
- Purchased Fame Coins, promotional/QA coins, Reward Reserve funds, and creator cash earnings remain separate accounting concepts.
- Public Fame Coin buying belongs on normal customer surfaces such as Profile and the Live gift flow. It must not be hidden inside Creator Studio or the Owner Control Center.
- Creator Studio remains focused on creator earnings, verification, payout setup, payout history, and clearly labeled promotional/non-withdrawable creator reporting.
- Owner Control Center remains focused on owner/admin business controls such as payout moderation, liabilities, reserves, and explicit reward funding.
- Apple IAP and PayPal must not be broken or silently removed while Stripe is added.

## Initially approved Stripe packs

- 100 Fame Coins — $0.99 USD
- 1,000 Fame Coins — $9.99 USD
- 5,000 Fame Coins — $49.99 USD

Do not invent Stripe prices for other Fame Coin quantities. Additional packs require explicit product approval and server-side catalog updates.

## Release state

Stripe source, catalog, database support, Checkout Session creation, webhook fulfillment, and client wiring may advance through automated validation as a FIX_CANDIDATE. Stripe is not release-locked until test-mode end-to-end payment QA passes and the required Build 23 physical-device regression checks pass. Live-mode charging must not be enabled merely because the Stripe account is payment-ready.
