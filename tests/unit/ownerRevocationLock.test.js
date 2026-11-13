import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const ui = readFileSync(new URL('../../src/components/web/OwnerConsoleWorkspace.jsx', import.meta.url), 'utf8')
const gate = readFileSync(new URL('../../src/components/web/WebOwnerCommandCenter.jsx', import.meta.url), 'utf8')

describe('Owner Command Center revoked-access regression lock', () => {
  it('requires a fresh owner-protected request after every section navigation', () => {
    expect(ui).not.toContain('cachedReads.current.get(')
    expect(ui).not.toContain('cachedReads.current.set(')
    expect(ui).toContain("fetch('/api/owner/console'")
  })
  it('locks all protected state on auth or network denial, even for non-JSON replies', () => {
    expect(ui.match(/response\.status === 401 \|\| response\.status === 403/g)).toHaveLength(2)
    expect(ui).toContain('setData({key:null')
    expect(ui).toContain('setPreviewHistory([])')
    expect(ui).toContain('setActionResult(null)')
    expect(ui).toContain('setActionOpen(false)')
    expect(ui).toContain('onLock()')
    expect(gate).toContain("state:'locked'")
  })
})
