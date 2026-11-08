import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8')
const store = read('src/components/web/WebStore.jsx')
const header = read('src/components/web/WebHeader.jsx')
const community = read('src/components/web/WebCommunity.jsx')
const settings = read('src/components/web/WebSettingsPage.jsx')
const profile = read('src/components/web/WebProfilePage.jsx')
const sale = read('src/components/web/WebBlackFriday.jsx')
const routes = JSON.parse(read('vercel.json'))

describe('web account and navigation repair contract', () => {
  it('makes Settings available on direct route and account menu without disturbing /coins', () => {
    expect(routes.rewrites).toEqual(expect.arrayContaining([
      {source: '/settings', destination: '/index.html'},
      {source: '/coins', destination: '/index.html'},
      {source: '/reset-password', destination: '/index.html'},
    ]))
    expect(header).toContain('href="/settings"')
    expect(header).toContain('My profile')
    expect(store).toContain("window.location.pathname === '/settings'")
    expect(store).toContain('<WebSettingsPage account={account} />')
    expect(store).toContain('settingsRequested) && !signedIn')
  })
  it('opens creator profiles instead of details-only dialog and preserves the real follow action', () => {
    expect(community).toContain('window.location.assign(`/?profile=')
    expect(store).toContain('<WebProfilePage profileId={profileId}')
    expect(profile).toContain("supabase.from('follows')")
  })
  it('preserves Black Friday and existing Stripe checkout flow', () => {
    expect(store).toContain('<WebBlackFridayBanner />')
    expect(store).toContain('<WebBlackFridayPreview')
    expect(store).toContain("supabase.functions.invoke('stripe-checkout-session'")
    expect(store).toContain("action: 'create', pack_id: pack.id, origin_context: 'web'")
    expect(sale).toContain("SALE_END_AT = Date.parse('2026-12-07T20:56:27.556Z')")
  })
  it('makes reset route work with or without validated recovery session', () => {
    expect(store).toContain('account.recoveryAuthorized && Boolean(account.session?.user)')
    expect(store).toContain('account.requestPasswordReset()')
    expect(settings).toContain("redirectTo: 'https://fameverse.app/reset-password'")
  })
})
