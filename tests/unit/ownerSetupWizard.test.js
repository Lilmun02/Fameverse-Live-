import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read = p => readFileSync(new URL('../../'+p, import.meta.url),'utf8')
describe('removed unapproved security-code wizard',()=>{
  it('uses existing account and email verification with exact IP allowlist',()=>{
    const owner=read('src/components/web/WebOwnerCommandCenter.jsx')
    const server=read('src/server/ownerSecurity.mjs')
    expect(owner).toContain('Send verification email')
    expect(owner).not.toContain('Prepare secure setup')
    expect(server).toContain('OWNER_ALLOWED_IPS')
    expect(server).not.toContain('OWNER_ACCESS_CODE')
  })
})
