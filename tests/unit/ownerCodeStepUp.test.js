import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { recentlyPasswordSignedIn, recentlyEmailCodeVerified } from '../../src/server/ownerSecurity.mjs'
const source = p => readFileSync(new URL('../../'+p, import.meta.url),'utf8')
const api = source('api/owner/control.js')
const view = source('src/components/web/WebOwnerCommandCenter.jsx')
const now = 1794141000
const claim = (method, timestamp=now) => ({is_anonymous:false,amr:[{method,timestamp}]})
describe('owner two-step email-code gate',()=>{
  it('requires fresh, distinct password and numeric email OTP methods',()=>{
    expect(recentlyPasswordSignedIn(claim('password'),now)).toBe(true)
    expect(recentlyPasswordSignedIn(claim('otp'),now)).toBe(false)
    expect(recentlyEmailCodeVerified(claim('otp'),now)).toBe(true)
    expect(recentlyEmailCodeVerified(claim('magiclink'),now)).toBe(false)
    expect(recentlyEmailCodeVerified(claim('password'),now)).toBe(false)
    expect(recentlyEmailCodeVerified(claim('otp',now-601),now)).toBe(false)
  })
  it('verifies submitted six-digit codes on the server for the SAME owner account',()=>{
    expect(api).toContain("verifier.auth.verifyOtp({")
    expect(api).toContain("type: 'email'")
    expect(api).toContain("checked?.user?.id !== auth.user.id")
    expect(api).toContain("checked?.user?.email !== auth.user.email")
    expect(api).toContain("scopedClient.rpc('get_owner_finance_control_summary')")
    expect(api).toContain("if (!passwordVerifiedRecently)")
  })
  it('prevents emails and summary access until server confirms numeric-code activation',()=>{
    expect(api).toContain("process.env.OWNER_EMAIL_OTP_ENABLED === 'true'")
    expect(api).toContain('if (!emailOtpReady)')
    expect(view).toContain('!status.emailOtpReady')
    expect(view).toContain('if (!status?.emailOtpReady')
    expect(view).toContain("body: JSON.stringify({ action: 'summary', code: emailCode })")
    expect(view).toContain('status.observedIP')
    expect(view).not.toContain('X-Owner-Password-Proof')
  })
})
