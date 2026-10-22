import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { videoConstraints } from '../../src/utils/media.js'

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
  it('checks authenticated server policy before opening media', () => {
    const app = readFileSync(new URL('../../src/App.jsx', import.meta.url), 'utf8')
    const start = app.indexOf('const startLive = async () => {')
    const end = app.indexOf('const submitComment =', start)
    const handler = app.slice(start, end)
    expect(handler).toContain('if (!wasLive && POLICY_ENABLED)')
    expect(handler).toContain("await supabase.rpc('fv_policy_permissions')")
    expect(handler).toContain('data?.can_go_live !== true')
    expect(handler.indexOf("await supabase.rpc('fv_policy_permissions')"))
      .toBeLessThan(handler.indexOf('await live.startLive()'))
    expect(handler).toContain('return false')
  })
})
