import { describe, expect, it } from 'vitest'
import ownerHandler from '../../api/owner/control.js'

function mockResponse() {
  return {
    headers: {}, statusCode: null, body: null,
    setHeader(key, value) { this.headers[key] = value; return this },
    status(code) { this.statusCode = code; return this },
    json(data) { this.body = data; return this },
  }
}

describe('owner access endpoint locked by default', () => {
  it('refuses GET access and never serves privileged data', async () => {
    const response = mockResponse()
    await ownerHandler({ method: 'GET', headers: {} }, response)
    expect(response.statusCode).toBe(405)
    expect(response.headers.Allow).toBe('POST')
    expect(response.body?.summary).toBeUndefined()
    expect(response.headers['Cache-Control']).toContain('no-store')
  })
  it('fails closed without code hash and IP config, before any database calls', async () => {
    const keys = ['OWNER_ALLOWED_IPS','OWNER_ACCESS_CODE_SALT','OWNER_ACCESS_CODE_SCRYPT_HASH']
    const saved = Object.fromEntries(keys.map((key) => [key, process.env[key]]))
    try {
      for (const key of keys) delete process.env[key]
      const response = mockResponse()
      await ownerHandler({
        method: 'POST',
        headers: { host: 'example.test', origin: 'https://example.test', 'x-vercel-forwarded-for': '203.0.113.8' },
        body: { action: 'summary', code: 'strong-test-code-0123' },
      }, response)
      expect(response.statusCode).toBe(503)
      expect(response.body?.authorized).toBeUndefined()
      expect(response.body?.summary).toBeUndefined()
    } finally {
      for (const key of keys) {
        if (saved[key] === undefined) delete process.env[key]
        else process.env[key] = saved[key]
      }
    }
  })
})
