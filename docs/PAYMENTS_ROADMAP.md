# Fameverse Payments Rollout

## Current candidate

- Fame Coin recharge uses Fameverse native UI -> Supabase API -> PayPal Sandbox.
- The visible fixed recharge packs are 100 Fame Coins for $0.99, 1,000 for $9.99, and 5,000 for $49.99, plus a separate custom amount option.
- Stripe is not part of the current recharge path.

## Stripe decision gate

Do not add or wire Stripe before Fameverse reaches at least 500 active users **and** the CEO explicitly approves a Stripe rollout after reviewing account/business readiness.

This is a product/release gate, not an instruction to automatically enable Stripe when the user count reaches 500.
