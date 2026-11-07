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
