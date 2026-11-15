import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const catalog = read('native/flutter_v1/lib/data/fameverse_live_backend.dart')
const tray = read('native/flutter_v1/lib/features/live/native_live_components.dart')
const retiredScript = read('scripts/apply-integration-live-repair.mjs')

describe('Build 48 owner-retired Fame Burst regression', () => {
  it('does not include the retired gift in native catalog or Trending', () => {
    expect(catalog).not.toContain("id: 'fame-burst'")
    expect(tray).not.toContain("'fame-burst',")
  })

  it('stops obsolete integration script before any file edits', () => {
    const stop = retiredScript.indexOf("throw new Error('RETIRED:")
    const firstMutation = retiredScript.indexOf('function write(')
    expect(stop).toBeGreaterThan(0)
    expect(firstMutation).toBeGreaterThan(stop)
    expect(retiredScript).toContain('do not execute the legacy integration repair script.')
  })
})
