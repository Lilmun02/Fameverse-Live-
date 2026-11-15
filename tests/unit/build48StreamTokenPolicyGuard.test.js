import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const source = readFileSync(
  new URL('../../supabase/functions/stream-token/index.ts', import.meta.url),
  'utf8',
)
const hostStart = source.indexOf('if (role === "host") {')
const policyStart = source.indexOf('"get_my_fameverse_policy_status"', hostStart)
const denyStart = source.indexOf('error: "policy-restricted-host"', policyStart)
const signStart = source.indexOf('await signUserToken(', policyStart)
const hostGuard = source.slice(hostStart, signStart)

describe('Build 48 Stream token host policy fail-closed contract', () => {
  it('checks host policy before signing while preserving the viewer route', () => {
    expect(hostStart).toBeGreaterThan(0)
    expect(policyStart).toBeGreaterThan(hostStart)
    expect(denyStart).toBeGreaterThan(policyStart)
    expect(signStart).toBeGreaterThan(denyStart)
    expect(source).toContain('role === "host" && !isHost')
    expect(source).toContain('error: "policy-status-unavailable"')
    expect(source).toContain('["host", "viewer"].includes(role)')
  })

  it('rejects absent, multiple, and account/version-mismatched policy rows', () => {
    expect(hostGuard).toContain('statusRows.length === 1')
    expect(hostGuard).toMatch(/!status\s*\|\|/)
    expect(hostGuard).toContain('status.user_id !== user.id')
    expect(hostGuard).toContain('status.policy_version !== "2026-10"')
    expect(hostGuard).not.toContain('if (status &&')
  })

  it('requires accepted backend authorization and never grants unsigned host tokens', () => {
    expect(hostGuard).toContain('status.decision !== "accepted"')
    expect(hostGuard).toContain('status.can_use_restricted !== true')
    expect(hostGuard).toContain('{ p_policy_version: "2026-10" }')
    expect(hostGuard).not.toContain('Date.now()')
    expect(hostGuard).not.toContain('status.decision === "unsigned"')
  })
})
