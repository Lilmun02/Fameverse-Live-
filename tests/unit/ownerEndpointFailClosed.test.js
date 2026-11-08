import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read = p => readFileSync(new URL('../../'+p,import.meta.url),'utf8')
describe('owner API fails closed by source IP',()=>{
  it('never supplies a public, unverified dashboard or readiness status',()=>{
    const source=read('api/owner/control.js')
    expect(source).toContain("if (req.method !== 'POST')")
    expect(source).toContain("if (!ownerIPAllowed(gate, trustedRequestIP(req.headers)))")
    expect(source).not.toContain("req.method === 'GET'")
  })
})
