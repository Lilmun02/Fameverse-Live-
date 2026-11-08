import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const store = read('src/components/web/WebStore.jsx')
const header = read('src/components/web/WebHeader.jsx')
const community = read('src/components/web/WebCommunity.jsx')
const blackFriday = read('src/components/web/WebBlackFriday.jsx')
const css = read('src/styles/web/black-friday.css')
const routes = JSON.parse(read('vercel.json'))

describe('standalone pages and perpetual ticker', () => {
  it('uses dedicated routes for navigation instead of scrolling through Home', () => {
    expect(routes.rewrites).toEqual(expect.arrayContaining([
      { source: '/discover', destination: '/index.html' },
      { source: '/coins', destination: '/index.html' },
      { source: '/settings', destination: '/index.html' },
      { source: '/profile/:id', destination: '/index.html' },
    ]))
    expect(header).toContain('href="/discover"')
    expect(header).toContain('href="/settings"')
    expect(header).toContain('href={`/profile/')
    expect(community).toContain('window.location.assign(`/profile/')
    expect(blackFriday).toContain('href="/coins"')
    expect(blackFriday).not.toContain('#coin-packs')
    expect(store).not.toContain('scrollIntoView')
    expect(store).toContain("if (window.location.pathname === '/reset-password')")
  })
  it('renders two equal width sequences long enough to cross the entire viewport', () => {
    expect(blackFriday).toContain('Array.from({ length: 4 }')
    expect(blackFriday).toContain('<TickerSequence sale={sale} /><TickerSequence sale={sale} />')
    expect(css).toContain('.fv-bf-ticker-sequence {')
    expect(css).toContain('animation: fv-bf-marquee 18s linear infinite')
    expect(css).toContain('to { transform: translate3d(-50%, 0, 0); }')
    expect(css).toContain('overflow: hidden')
  })
  it('preserves sale and checkout integration and redirects old bookmarks', () => {
    expect(blackFriday).toContain('SALE_END_AT = Date.parse')
    expect(blackFriday).toContain('pack && onCheckout?.(pack)')
    expect(store).toContain('onCheckout={startCheckout}')
    expect(store).toContain("supabase.functions.invoke('stripe-checkout-session'")
    expect(store).toContain("fragment === '#discover-creators'")
    expect(store).toContain("window.location.replace('/discover')")
    expect(store).toContain("window.location.replace('/coins')")
  })
})
