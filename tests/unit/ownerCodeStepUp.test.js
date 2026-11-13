import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read = p => readFileSync(new URL('../../'+p,import.meta.url),'utf8')
describe('Owner Command Center no additional authentication',()=>{
  it('checks approved source IP on every privileged request, without numeric OTP',()=>{
    const api=read('api/owner/control.js')
    const page=read('src/components/web/WebOwnerCommandCenter.jsx')
    expect(api).toContain('trustedRequestIP(req.headers)')
    expect(api).toContain('client.auth.getUser(token)')
    expect(api).not.toContain('recentlyPasswordSignedIn')
    expect(api).not.toContain('verifyOtp')
    expect(page).not.toContain('emailCode')
  })
})
