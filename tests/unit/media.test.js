import { describe, expect, it, vi } from 'vitest'
import { readFileSync } from 'node:fs'
import { mayStartPolicyGatedLive, videoConstraints } from '../../src/utils/media.js'

describe('videoConstraints', () => {
  it('defaults to the user-facing camera', () => {
    expect(videoConstraints()).toEqual({
      facingMode: { ideal: 'user' },
      width: { ideal: 1280 },
      height: { ideal: 720 },
    })
  })

  it('preserves an environment-facing camera request', () => {
    expect(videoConstraints('environment').facingMode).toEqual({ ideal: 'environment' })
  })
})

describe('browser Go Live policy preflight', () => {
  it('does not request media or permissions when ending an existing Live', async () => {
    const rpc = vi.fn().mockRejectedValue(new Error('backend offline'))
    const onDenied = vi.fn()
    expect(await mayStartPolicyGatedLive({
      enabled: true, alreadyLive: true, rpc, onDenied,
    })).toBe(true)
    expect(rpc).not.toHaveBeenCalled()
    expect(onDenied).not.toHaveBeenCalled()
  })

  it('preserves previously approved hosting behavior when the gate is disabled', async () => {
    const rpc = vi.fn()
    expect(await mayStartPolicyGatedLive({
      enabled: false, alreadyLive: false, rpc, onDenied: vi.fn(),
    })).toBe(true)
    expect(rpc).not.toHaveBeenCalled()
  })

  it('permits hosting only when the authenticated server returns can_go_live=true', async () => {
    const rpc = vi.fn().mockResolvedValue({ data: { can_go_live: true }, error: null })
    const onDenied = vi.fn()
    expect(await mayStartPolicyGatedLive({
      enabled: true, alreadyLive: false, rpc, onDenied,
    })).toBe(true)
    expect(rpc).toHaveBeenCalledExactlyOnceWith('fv_policy_permissions')
    expect(onDenied).not.toHaveBeenCalled()
  })

  it.each([
    [{ can_go_live: false }, null],
    [{ decision: 'declined' }, null],
    [null, { message: 'authorization denied' }],
    [null, null],
  ])('fails closed on rejected, missing, or errored permissions', async (data, error) => {
    const rpc = vi.fn().mockResolvedValue({ data, error })
    const onDenied = vi.fn()
    expect(await mayStartPolicyGatedLive({
      enabled: true, alreadyLive: false, rpc, onDenied,
    })).toBe(false)
    expect(onDenied).toHaveBeenCalledExactlyOnceWith(
      'Accept Fameverse policies before going Live',
    )
  })

  it('fails closed when the policy RPC throws', async () => {
    const onDenied = vi.fn()
    expect(await mayStartPolicyGatedLive({
      enabled: true, alreadyLive: false,
      rpc: vi.fn().mockRejectedValue(new Error('unavailable')),
      onDenied,
    })).toBe(false)
    expect(onDenied).toHaveBeenCalledExactlyOnceWith(
      'Could not verify Go Live eligibility · please retry',
    )
  })

  it('locks the authorization ordering and guards overlapping start attempts in App', () => {
    const app = readFileSync(new URL('../../src/App.jsx', import.meta.url), 'utf8')
    const start = app.indexOf('const startLive = async () => {')
    const end = app.indexOf('const submitComment =', start)
    const handler = app.slice(start, end)
    expect(handler).toContain('policyLiveStartInProgressRef.current')
    expect(handler).toContain('if (!wasLive && POLICY_ENABLED && policyLiveStartInProgressRef.current)')
    expect(handler).toContain('if (!allowedToHost) return false')
    expect(handler.indexOf('await mayStartPolicyGatedLive('))
      .toBeLessThan(handler.indexOf('await live.startLive()'))
    expect(handler).toContain('policyLiveStartInProgressRef.current = false')
  })
})
