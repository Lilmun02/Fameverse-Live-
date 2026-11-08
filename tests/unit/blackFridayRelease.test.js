import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8')
}

const store = read('src/components/web/WebStore.jsx')
const sale = read('src/components/web/WebBlackFriday.jsx')
const styles = read('src/styles/web/black-friday.css')
const responsive = read('src/styles/web/platform-responsive.css')
const html = read('index.html')

describe('Black Friday live web release contract', () => {
  it('features exactly three owner-priced deals with full advertised coin amounts', () => {
    const rows = [
      ['stripe-bf2026-10000', '10,000', '25%', '$49.99', '$37.49'],
      ['stripe-bf2026-50000', '50,000', '60%', '$499.99', '$200.00'],
      ['stripe-bf2026-100000', '100,000', '80%', '$899.99', '$180.00'],
    ]
    for (const [id, coins, discount, regularPrice, saleSubtotal] of rows) {
      expect(sale).toContain(`packId: '${id}'`)
      expect(sale).toContain(`coins: '${coins}'`)
      expect(sale).toContain(`discount: '${discount}'`)
      expect(sale).toContain(`regularPrice: '${regularPrice}'`)
      expect(sale).toContain(`saleSubtotal: '${saleSubtotal}'`)
    }
    expect(sale.match(/featured: true/g)).toHaveLength(1)
    expect(sale).toMatch(/packId: 'stripe-bf2026-100000',[\s\S]*?featured: true/)
    expect(sale).toContain('fv-bf-popular">POPULAR')
  })

  it('uses the actual active sale dates, 30-day-plus calendar-month countdown and real purchase routes', () => {
    expect(sale).toContain('2026-11-07T20:56:27.556Z')
    expect(sale).toContain('2026-12-07T20:56:27.556Z')
    expect(sale).toContain('Ends December 7, 2026 at 3:56 PM EST')
    expect(sale).toContain('pack && onCheckout?.(pack)')
    expect(sale).toContain('https://fameverse.app/coins')
    expect(store).toContain('onCheckout={startCheckout}')
    expect(store).toContain('salePacks={stripeConfig?.packs ?? []}')
    expect(store).toContain('<WebBlackFridayBanner />')
    expect(sale).not.toContain('FINAL PRICE COMING SOON')
    expect(sale).not.toContain('SALE NOT ACTIVE YET')
    expect(styles).toContain('.fv-bf-buy')
    expect(styles).toContain('prefers-reduced-motion: reduce')
  })

  it('contains the mobile phone portrait/landscape rules and hides the Vercel overlay', () => {
    expect(html).toContain('vercel-live-feedback,')
    expect(html).toContain('display: none !important')
    expect(responsive).toContain('@media (orientation: landscape)')
    expect(responsive).toContain('.fv-bf-offers { grid-template-columns: minmax(0, 1fr); }')
  })
})
