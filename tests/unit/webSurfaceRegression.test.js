import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

function source(path) {
  return readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8')
}

const store = source('src/components/web/WebStore.jsx')
const header = source('src/components/web/WebHeader.jsx')
const sidebar = source('src/components/web/WebSidebar.jsx')
const settings = source('src/components/web/WebSettingsPage.jsx')
const wallet = source('src/components/web/WebWallet.jsx')
const account = source('src/hooks/useAccount.js')
const hero = source('src/components/web/WebHero.jsx')
const community = source('src/components/web/WebCommunity.jsx')
const profile = source('src/components/web/WebProfilePage.jsx')
const layoutStyles = source('src/styles/web/platform-layout.css')
const communityStyles = source('src/styles/web/platform-community.css')
const blackFriday = source('src/components/web/WebBlackFriday.jsx')
const blackFridayStyles = source('src/styles/web/black-friday.css')
const rewrites = JSON.parse(source('vercel.json')).rewrites

describe('Fameverse web regression contract', () => {
  it('keeps future information topics in header and footer, not on homepage or sidebar', () => {
    const topics = ['Announcements', 'Features & benefits', 'Upcoming updates', 'Events']
    for (const topic of topics) {
      expect(header).toContain(topic)
      expect(store).toContain(topic)
      expect(sidebar).not.toContain(topic)
    }
    expect(store).not.toContain('WebNewsHub')
    expect(store).not.toContain('<WebWallet')
    expect(header).not.toContain('href="/#announcements"')
    expect(header).not.toContain('href="/#updates"')
    expect(header).not.toContain('href="/#events"')
  })

  it('ends the left sidebar after Fame Coins without extra promo or footer content', () => {
    expect(sidebar).toContain('For you')
    expect(sidebar).toContain('Creators')
    expect(sidebar).toContain('Fame Coins')
    expect(sidebar).not.toContain('Your people.')
    expect(sidebar).not.toContain('Join the conversation')
    expect(sidebar).not.toContain('Account recovery')
    expect(sidebar).not.toContain('fv-platform-sidebar-note')
    expect(sidebar).not.toContain('fv-platform-sidebar-footer')
    expect(store).toContain('<WebSidebar />')
  })

  it('keeps one functioning hero action and no leftover decorative art layer', () => {
    expect(hero).toContain('href="#discover-creators"')
    expect(hero).not.toContain('Support a creator')
    expect(hero).not.toContain('fv-platform-hero-art')
    expect(layoutStyles).not.toContain('.fv-platform-hero-art')
    expect(communityStyles).not.toContain('transform: rotate(-7deg)')
  })

  it('displays every recommended creator and presents bios without clipping profile pictures', () => {
    expect(community).toContain('creatorResults.map((item)')
    expect(community).not.toContain('creatorResults.slice(0, 8)')
    expect(communityStyles).not.toContain('-webkit-line-clamp: 2')
    expect(communityStyles).toContain('overflow-wrap: anywhere;')
    expect(profile).toContain('<h2>Bio</h2>')
    expect(profile).toContain('profile.bio?.trim()')
    expect(profile).not.toContain('className="fv-profile-page-bio"')
    expect(layoutStyles).toContain('margin-top: 24px; position: relative;')
    expect(layoutStyles).not.toContain('margin-top: -65px')
    expect(layoutStyles).not.toContain('.fv-profile-page-top { margin-top: -48px')
  })

  it('keeps the Black Friday marquee and 3 full-coin offers preview-only', () => {
    expect(store).toContain('<WebBlackFridayBanner />')
    expect(store).toContain('<WebBlackFridayPreview />')
    expect(blackFriday).toContain('NOV 27–30 · WEEKEND SALE PREVIEW')
    expect(blackFriday).toContain('SALE NOT ACTIVE YET')
    expect(blackFriday).toContain("coins: '10,000'")
    expect(blackFriday).toContain('$49.99 regular · $37.49 after discount, before tax')
    expect(blackFriday).toContain('NOV 27–30 PROPOSED · BLACK FRIDAY WEEKEND PREVIEW')
    expect(blackFriday).toContain('All three Black Friday packs featured.')
    expect(blackFriday).toContain('Final sale closing time subject to owner approval.')
    expect(blackFriday).not.toContain('NOV 27 ONLY')
    expect(blackFriday).not.toContain('Sale ends at midnight Eastern on November 28.')
    expect(blackFriday).toContain("coins: '50,000'")
    expect(blackFriday).toContain("coins: '100,000'")
    expect(blackFriday).toContain("discount: '25%'")
    expect(blackFriday).toContain("discount: '60%'")
    expect(blackFriday).toContain("discount: '80%'")
    expect(blackFriday).toMatch(/coins: '50,000',[\s\S]*?featured: false/)
    expect(blackFriday).toMatch(/coins: '100,000',[\s\S]*?featured: true/)
    expect(blackFriday.match(/featured: true/g)).toHaveLength(1)
    expect(blackFriday).toContain('offer.featured && <span className="fv-bf-popular">POPULAR</span>')
    expect(blackFridayStyles).toContain('.fv-bf-popular {')
    expect(blackFriday).toContain('FINAL PRICE COMING SOON')
    expect(blackFriday).not.toContain('<button')
    expect(blackFriday).not.toContain('startCheckout')
    expect(blackFridayStyles).toContain('animation: fv-bf-marquee')
    expect(blackFridayStyles).toContain('prefers-reduced-motion: reduce')
  })

  it('preserves usable web routes for settings, coin shop and password reset', () => {
    for (const path of ['/settings', '/coins', '/reset-password']) {
      expect(rewrites).toContainEqual({ source: path, destination: '/index.html' })
    }
    expect(header).toContain('href="/settings"')
    expect(store).toContain("const settingsRequested = window.location.pathname === '/settings'")
    expect(store).toContain('(authOpen || settingsRequested) && !signedIn')
  })

  it('keeps wallet inside settings without turning promotional coins into owner test coins', () => {
    expect(settings).toContain('<WebWallet userId={user?.id}')
    expect(store).not.toContain('WebWallet')
    expect(wallet).toContain("accountRole === 'owner'")
    expect(wallet).not.toContain('format(wallet.promo_coins)')
    expect(wallet).toContain('awaiting verified Ruby conversion')
  })

  it('only shows the new password form with a verified recovery session', () => {
    expect(store).toContain('account.recoveryAuthorized && Boolean(account.session?.user)')
    expect(store).toContain('account.requestPasswordReset()')
    expect(account).toContain('recoveryMode, recoveryAuthorized, recoveryPassword')
    expect(account).toContain("redirectTo: 'https://fameverse.app/reset-password'")
  })
})
