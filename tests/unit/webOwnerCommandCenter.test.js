import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { configuredOwnerGate, ownerIPAllowed, recentlyEmailCodeVerified, trustedRequestIP } from '../../src/server/ownerSecurity.mjs'

const read = (path) => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const server = read('api/owner/control.js')
const ownerPage = read('src/components/web/WebOwnerCommandCenter.jsx')
const store = read('src/components/web/WebStore.jsx')
const routes = JSON.parse(read('vercel.json'))

describe('Owner Command Center sign-in / verified email / IP gate', () => {
  it('fails closed without a single explicit IP allowlist', () => {
    expect(configuredOwnerGate({})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '*'})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '203.0.113.6,203.0.113.7'})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '203.0.113.6'})).toEqual({allowedIPs:['203.0.113.6']})
    expect(ownerIPAllowed(configuredOwnerGate({OWNER_ALLOWED_IPS:'203.0.113.6'}),'203.0.113.7')).toBe(false)
    expect(ownerIPAllowed(configuredOwnerGate({OWNER_ALLOWED_IPS:'203.0.113.6'}),'203.0.113.6')).toBe(true)
  })
  it('accepts only server-provided Vercel IP header', () => {
    expect(trustedRequestIP({'x-vercel-forwarded-for':'203.0.113.6'})).toBe('203.0.113.6')
    expect(trustedRequestIP({'x-forwarded-for':'203.0.113.6'})).toBeNull()
    expect(trustedRequestIP({'x-vercel-forwarded-for':'203.0.113.6, 192.0.2.1'})).toBeNull()
  })
  it('requires verified recent numeric OTP, not ordinary links or password', () => {
    const now=1794000000
    expect(recentlyEmailCodeVerified({amr:[{method:'password',timestamp:now}]},now)).toBe(false)
    expect(recentlyEmailCodeVerified({amr:[{method:'otp',timestamp:now-60}]},now)).toBe(true)
    expect(recentlyEmailCodeVerified({amr:[{method:'magiclink',timestamp:now-60}]},now)).toBe(false)
    expect(recentlyEmailCodeVerified({amr:[{method:'otp',timestamp:now-1200}]},now)).toBe(false)
    expect(recentlyEmailCodeVerified(null,now)).toBe(false)
  })
  it('enforces account email confirmation, owner role, verified JWT claims, IP before RPC', () => {
    expect(server).toContain('auth.user.email_confirmed_at')
    expect(server).toContain("role?.role !== 'owner'")
    expect(server).toContain('client.auth.getUser(token)')
    expect(server).toContain('client.auth.getClaims(token)')
    expect(server).toContain('recentlyPasswordSignedIn(claims)')
    expect(server).toContain('ownerIPAllowed(gate, requestIP)')
    expect(server).toContain("scopedClient.rpc('get_owner_finance_control_summary')")
    expect(server).not.toContain('SERVICE_ROLE')
    expect(server).not.toContain('ownerCodeMatches')
  })
  it('supports email verification in web preview and has no security-code setup wizard', () => {
    expect(routes.rewrites).toContainEqual({source:'/owner',destination:'/index.html'})
    expect(store).toContain('<WebOwnerCommandCenter account={account} />')
    expect(ownerPage).toContain('!status.emailOtpReady')
    expect(ownerPage).toContain('supabase.auth.signInWithOtp')
    expect(ownerPage).not.toContain('supabase.auth.verifyOtp')
    expect(server).toContain('verifier.auth.verifyOtp')
    expect(ownerPage).toContain('Owner email-code verification pending')
    expect(ownerPage).toContain("body: JSON.stringify({ action: 'summary', code: emailCode })")
    expect(ownerPage).toContain('IP approval required')
    expect(ownerPage).not.toContain('OWNER_ACCESS_CODE_')
    expect(ownerPage).not.toContain('Prepare secure setup')
  })
})
