import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { configuredOwnerGate, trustedRequestIP, ownerIPAllowed } from '../../src/server/ownerSecurity.mjs'

const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const api = read('api/owner/control.js')
const page = read('src/components/web/WebOwnerCommandCenter.jsx')
const routes = JSON.parse(read('vercel.json'))

describe('Owner account + one-IP only preview security', () => {
  it('fails closed without one valid configured public IP', () => {
    expect(configuredOwnerGate({})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '*'})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '203.0.113.6,203.0.113.7'})).toBeNull()
    expect(configuredOwnerGate({OWNER_ALLOWED_IPS: '203.0.113.6'})).toEqual({allowedIPs:['203.0.113.6']})
    expect(ownerIPAllowed(configuredOwnerGate({OWNER_ALLOWED_IPS:'203.0.113.6'}),'203.0.113.7')).toBe(false)
  })
  it('checks only the Vercel-injected IP and rejects malformed or chained values', () => {
    expect(trustedRequestIP({'x-vercel-forwarded-for':'203.0.113.6'})).toBe('203.0.113.6')
    expect(trustedRequestIP({'x-forwarded-for':'203.0.113.6'})).toBeNull()
    expect(trustedRequestIP({'x-vercel-forwarded-for':'203.0.113.6, 192.0.2.1'})).toBeNull()
    expect(trustedRequestIP({})).toBeNull()
  })
  it('requires verified account and owner role after the IP check', () => {
    expect(api).toContain('ownerIPAllowed(gate, trustedRequestIP(req.headers))')
    expect(api).toContain('client.auth.getUser(token)')
    expect(api).toContain('auth.user.email_confirmed_at')
    expect(api).toContain("role?.role !== 'owner'")
    expect(api).toContain("client.rpc('get_owner_finance_control_summary')")
    expect(api).not.toContain('OWNER_EMAIL_OTP_ENABLED')
    expect(api).not.toContain('verifyOtp')
    expect(api).not.toContain('SERVICE_ROLE')
  })
  it('automatically opens a read-only overview after owner login, without extra verification', () => {
    expect(routes.rewrites).toContainEqual({source:'/owner',destination:'/index.html'})
    expect(page).toContain("fetch('/api/owner/control'")
    expect(page).toContain("credentials: 'same-origin'")
    expect(page).toContain('Authorization: `Bearer ${token}`')
    expect(page).toContain("body: JSON.stringify({ action: 'summary' })")
    expect(page).toContain("data?.code === 'NETWORK_DENIED'")
    expect(page).toContain('Network blocked')
    expect(page).not.toContain('supabase.auth.signInWithOtp')
    expect(page).not.toContain('verifyOtp')
    expect(page).not.toContain('Send six-digit email code')
  })
})
