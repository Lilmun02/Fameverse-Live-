import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const checkoutSource = readFileSync(new URL('../../supabase/functions/stripe-checkout-session/index.ts', import.meta.url), 'utf8')

describe('Black Friday Stripe server-side expiration', () => {
  it('guards exactly the three discounted Black Friday packages', () => {
    expect(checkoutSource).toContain('new Set(["stripe-bf2026-10000", "stripe-bf2026-50000", "stripe-bf2026-100000"])')
    expect(checkoutSource).toContain('2026-12-07T20:56:27.556Z')
    expect(checkoutSource).toContain('BLACK_FRIDAY_PACK_IDS.has(id) && Date.now() >= BLACK_FRIDAY_END_AT')
  })

  it('hides expired packs from checkout config and rejects any new Stripe session', () => {
    expect(checkoutSource).toContain('!isExpiredBlackFridayPack(String(raw.id ?? ""))')
    expect(checkoutSource).toContain('if (isExpiredBlackFridayPack(packId)) return json(410, { error: "black-friday-sale-ended" });')
    expect(checkoutSource).toContain('claim_stripe_checkout_order')
    expect(checkoutSource).toContain('fv-stripe-checkout-${claim.order_id}')
  })

  it('preserves JWT authentication and existing Stripe purchase pricing from the pack', () => {
    expect(checkoutSource).toContain('if (!authorization.startsWith("Bearer "))')
    expect(checkoutSource).toContain('const priceCents = priceForEnvironment(pack, environment)')
    expect(checkoutSource).toContain('form.set("line_items[0][price_data][unit_amount]", String(priceCents))')
    expect(checkoutSource).toContain('form.set("metadata[coins]", String(pack.coins))')
  })
})
