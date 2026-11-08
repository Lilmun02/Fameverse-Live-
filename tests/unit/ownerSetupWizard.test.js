import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
const read = p => readFileSync(new URL('../../'+p,import.meta.url),'utf8')
describe('removed unapproved owner code verification',()=>{
  it('requires only Fameverse account and approved IP',()=>{
    const page=read('src/components/web/WebOwnerCommandCenter.jsx')
    const gate=read('src/server/ownerSecurity.mjs')
    expect(page).toContain('Sign in to Fameverse')
    expect(page).toContain('Checking account and IP')
    expect(page).not.toContain('Send verification email')
    expect(page).not.toContain('Send six-digit email code')
    expect(gate).toContain('OWNER_ALLOWED_IPS')
    expect(gate).not.toContain('OWNER_ACCESS_CODE')
  })
})
