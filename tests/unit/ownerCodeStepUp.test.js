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
  it('authenticates both tokens to the SAME owner identity',()=>{
    expect(api).toContain('proofIdentity.data?.user?.id === auth.user.id')
    expect(api).toContain('proofIdentity.data?.user?.email === auth.user.email')
    expect(api).toContain('proofClaims.data?.claims?.sub === auth.user.id')
    expect(api).toContain('!passwordVerifiedRecently || !emailVerifiedRecently')
  })
  it('prevents emails and summary access until server confirms numeric-code activation',()=>{
    expect(api).toContain("process.env.OWNER_EMAIL_OTP_ENABLED === 'true'")
    expect(api).toContain('if (!emailOtpReady)')
    expect(view).toContain('!status.emailOtpReady')
    expect(view).toContain('if (!status?.emailOtpReady')
    expect(view).toContain('data?.user?.id !== originalId')
    expect(view).toContain('status.observedIP')
    expect(view).toContain('X-Owner-Password-Proof')
  })
})
