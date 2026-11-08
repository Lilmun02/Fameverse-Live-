import { describe, it, expect } from 'vitest'
import { scryptSync } from 'node:crypto'
import { configuredOwnerGate, trustedRequestIP, ownerIPAllowed, ownerCodeMatches } from '../../src/server/ownerSecurity.mjs'
import { readFileSync } from 'node:fs'

const read = (name) => readFileSync(new URL('../../' + name, import.meta.url), 'utf8')
const client = read('src/components/web/WebOwnerCommandCenter.jsx')
const webStore = read('src/components/web/WebStore.jsx')
const server = read('api/owner/control.js')
const routes = JSON.parse(read('vercel.json'))
const config = {
  OWNER_ALLOWED_IPS: '203.0.113.8, 2001:db8::3',
  OWNER_ACCESS_CODE_SALT: 'test-salt-0123456789',
  OWNER_ACCESS_CODE_SCRYPT_HASH: scryptSync('strong-test-code-0123', 'test-salt-0123456789', 64).toString('hex'),
}

describe('Owner Command Center secure preview gate', () => {
  it('fails closed when any security setting is absent or invalid', () => {
    expect(configuredOwnerGate({})).toBeNull()
    expect(configuredOwnerGate({ ...config, OWNER_ALLOWED_IPS: '' })).toBeNull()
    expect(configuredOwnerGate({ ...config, OWNER_ACCESS_CODE_SCRYPT_HASH: '0' })).toBeNull()
    expect(configuredOwnerGate({ ...config, OWNER_ALLOWED_IPS: '*' })).toBeNull()
  })
  it('accepts only trusted Vercel forwarded IP on the explicit owner allowlist', () => {
    const gate = configuredOwnerGate(config)
    expect(gate).toBeTruthy()
    expect(trustedRequestIP({ 'x-vercel-forwarded-for': '203.0.113.8' })).toBe('203.0.113.8')
    expect(ownerIPAllowed(gate, '203.0.113.8')).toBe(true)
    expect(ownerIPAllowed(gate, '203.0.113.9')).toBe(false)
    expect(trustedRequestIP({ 'x-forwarded-for': '203.0.113.8' })).toBeNull()
    expect(trustedRequestIP({ 'x-vercel-forwarded-for': '203.0.113.8,10.0.0.1' })).toBeNull()
  })
  it('compares security code against a salted scrypt hash, never plaintext', () => {
    const gate = configuredOwnerGate(config)
    expect(ownerCodeMatches(gate, 'strong-test-code-0123')).toBe(true)
    expect(ownerCodeMatches(gate, 'wrong-code-0123456')).toBe(false)
    expect(ownerCodeMatches(gate, 'short')).toBe(false)
  })
  it('protects server summary with account role, server code, IP and user JWT', () => {
    expect(server).toContain('configuredOwnerGate()')
    expect(server).toContain('ownerIPAllowed(gate, trustedRequestIP(req.headers))')
    expect(server).toContain("client.auth.getUser(token)")
    expect(server).toContain("accountRole?.role !== 'owner'")
    expect(server).toContain('ownerCodeMatches(gate, body.code)')
    expect(server).toContain("client.rpc('get_owner_finance_control_summary')")
    expect(server).not.toContain('SERVICE_ROLE')
  })
  it('exposes web-only standalone locked route without touching the native app', () => {
    expect(routes.rewrites).toContainEqual({ source: '/owner', destination: '/index.html' })
    expect(webStore).toContain("window.location.pathname === '/owner'")
    expect(webStore).toContain('<WebOwnerCommandCenter account={account} />')
    expect(client).toContain("account.profile?.account_role === 'owner'")
    expect(client).toContain("setSummary(null)")
    expect(client).toContain("credentials: 'omit'")
    expect(client).toContain("const [gateStatus, setGateStatus] = useState('checking')")
    expect(client).toContain("result.configured === true ? 'ready' : 'unconfigured'")
    expect(client).toContain("if (gateStatus !== 'ready')")
    expect(client).toContain('No owner security code or approved IP list has been configured')
  })
})
