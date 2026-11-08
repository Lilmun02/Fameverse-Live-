import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const source = readFileSync(new URL('../../src/components/web/WebOwnerCommandCenter.jsx', import.meta.url), 'utf8')
const server = readFileSync(new URL('../../api/owner/control.js', import.meta.url), 'utf8')

describe('Vercel-authenticated preview owner API requests', () => {
  it('preserves same-origin preview authentication for every owner POST request', () => {
    expect(source.match(/credentials: 'same-origin'/g)).toHaveLength(2)
    expect(source).not.toContain("credentials: 'omit'")
    expect(source).toContain("fetch('/api/owner/control'")
    expect(source).not.toContain('fetch(\'https://')
  })

  it('does not confuse an HTML/SSO response with an owner-role denial', () => {
    expect(source).toContain("response.headers.get('content-type')")
    expect(source).toContain("contentType.includes('application/json')")
    expect(source).toContain('The preview access session could not be verified.')
  })

  it('still requires an independent Supabase bearer token, confirmed email and owner role', () => {
    expect(source).toContain('Authorization: `Bearer ${token}`')
    expect(server).toContain('client.auth.getUser(token)')
    expect(server).toContain('auth.user.email_confirmed_at')
    expect(server).toContain("role?.role !== 'owner'")
    expect(server).toContain('ownerIPAllowed(gate, requestIP)')
    expect(server).toContain('recentlyPasswordSignedIn(claims)')
  })
})
