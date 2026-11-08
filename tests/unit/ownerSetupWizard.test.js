import { describe, expect, it } from 'vitest'
import { prepareOwnerGateMaterial, configuredOwnerGate, ownerCodeMatches } from '../../src/server/ownerSecurity.mjs'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const api = read('api/owner/control.js')
const page = read('src/components/web/WebOwnerCommandCenter.jsx')
const styles = read('src/styles/web/platform-owner.css')

describe('owner setup wizard', () => {
  it('prepares credentials without storing or returning plaintext', () => {
    const code = 'my-strong-private-owner-code-001'
    const prepared = prepareOwnerGateMaterial(code, '203.0.113.42')
    expect(prepared).toEqual({allowedIP:'203.0.113.42',salt:expect.any(String),hash:expect.any(String)})
    expect(prepared.hash).toHaveLength(128)
    expect(prepared).not.toHaveProperty('code')
    expect(prepared.salt).toHaveLength(48)
    const gate = configuredOwnerGate({
      OWNER_ALLOWED_IPS: prepared.allowedIP,
      OWNER_ACCESS_CODE_SALT: prepared.salt,
      OWNER_ACCESS_CODE_SCRYPT_HASH: prepared.hash,
    })
    expect(ownerCodeMatches(gate, code)).toBe(true)
    expect(ownerCodeMatches(gate, 'wrong-private-code-001')).toBe(false)
  })
  it('rejects weak codes or untrusted IP addresses', () => {
    expect(prepareOwnerGateMaterial('short', '203.0.113.42')).toBeNull()
    expect(prepareOwnerGateMaterial('my-strong-private-owner-code-001', 'not-an-ip')).toBeNull()
  })
  it('prevents unauthorized or repeated setup', () => {
    expect(api).toContain("client.auth.getUser(token)")
    expect(api).toContain("accountRole?.role !== 'owner'")
    expect(api).toContain("if (gate)")
    expect(api).toContain("return reply(res, 409")
    expect(api).toContain("body.action === 'prepare'")
  })
  it('shows readable, real setup steps to signed-in owners before code entry', () => {
    expect(page).toContain("gateStatus === 'unconfigured'")
    expect(page).toContain('OWNER_ALLOWED_IPS')
    expect(page).toContain('OWNER_ACCESS_CODE_SALT')
    expect(page).toContain('OWNER_ACCESS_CODE_SCRYPT_HASH')
    expect(page).toContain("setPrepared(payload)")
    expect(styles).toContain('.fv-owner-setup-step h2')
    expect(styles).toContain('font-size:16px')
  })
})
