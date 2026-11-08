import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read = p => readFileSync(new URL('../../'+p,import.meta.url),'utf8')
const page = read('src/components/web/WebOwnerCommandCenter.jsx')
const api = read('api/owner/control.js')
describe('preview owner sign-in flow',()=>{
  it('keeps same-origin preview protection cookies and supplied Supabase JWT',()=>{
    expect(page).toContain("credentials: 'same-origin'")
    expect(page).not.toContain("credentials: 'omit'")
    expect(page).toContain('Authorization: `Bearer ${token}`')
  })
  it('distinguishes an HTML preview protection response from JSON',()=>{
    expect(page).toContain("response.headers.get('content-type')")
    expect(page).toContain("type.includes('application/json')")
  })
  it('is not an email OTP wizard anymore',()=>{
    expect(page).not.toContain('signInWithOtp')
    expect(page).not.toContain('verifyOtp')
    expect(page).not.toContain('emailOtpReady')
    expect(api).not.toContain('verifyOtp')
    expect(api).not.toContain('OWNER_EMAIL_OTP_ENABLED')
  })
})
