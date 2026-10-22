import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { evaluateHostPolicyAccess } from '../../supabase/functions/stream-token/host-policy.ts'

describe('server Stream host credential policy', () => {
  it('keeps viewer tokens available even for declined accounts', () => {
    expect(evaluateHostPolicyAccess({
      role: 'viewer', enabled: true, permissions: { can_go_live: false },
    })).toBe('allow')
  })

  it('does not impose unpublished policy rules while the server gate is off', () => {
    expect(evaluateHostPolicyAccess({
      role: 'host', enabled: false, error: new Error('not deployed'),
    })).toBe('allow')
  })

  it('allows newly issued host tokens only after authenticated eligibility', () => {
    expect(evaluateHostPolicyAccess({
      role: 'host', enabled: true, permissions: { can_go_live: true },
    })).toBe('allow')
    expect(evaluateHostPolicyAccess({
      role: 'host', enabled: true, permissions: { can_go_live: false },
    })).toBe('deny')
  })

  it.each([null, {}, { can_go_live: 'true' }])(
    'fails closed on missing or malformed permission replies',
    (permissions) => {
      expect(evaluateHostPolicyAccess({
        role: 'host', enabled: true, permissions,
      })).toBe('unavailable')
    },
  )

  it('fails closed when the permission lookup reports an error', () => {
    expect(evaluateHostPolicyAccess({
      role: 'host', enabled: true, error: new Error('db unavailable'),
      permissions: { can_go_live: true },
    })).toBe('unavailable')
  })

  it('only issues a signed host token after a verified user and RPC check', () => {
    const source = readFileSync(new URL('../../supabase/functions/stream-token/index.ts', import.meta.url), 'utf8')
    expect(source).toContain('userClient.auth.getUser()')
    expect(source).toContain('userClient.rpc(')
    expect(source).toContain('evaluateHostPolicyAccess(')
    expect(source.indexOf('userClient.rpc('))
      .toBeLessThan(source.indexOf('await signUserToken('))
  })
})
