import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const app = read('native/flutter_v1/lib/app/fameverse_app.dart')
const consent = read('native/flutter_v1/lib/features/profile/fameverse_policy_consent_screen.dart')
const service = read('native/flutter_v1/lib/data/fv_policy_acceptance_service.dart')
const sql = read('docs/review/BUILD48_POLICY_CHECKBOX_EVIDENCE_MIGRATION_REVIEW.sql')

describe('Build 48 native consent checkbox evidence, review only', () => {
  it('sends the actual checkbox state from the native screen', () => {
    expect(consent).toContain('final ValueChanged<bool> onAccept')
    expect(consent).toContain('() => widget.onAccept(_readAndAgree)')
    expect(consent).toContain('_readAndAgree &&')
    expect(app).toContain('_submitPolicyDecision(accept: true, checkboxChecked: checked)')
  })

  it('requires checkbox true for acceptance and binds the readback to the user', () => {
    expect(service).toContain('if (accept && !checkboxChecked)')
    expect(service).toContain("'checkbox_acknowledged': accept ? checkboxChecked : null")
    expect(service).toContain(".eq('user_id', user.id)")
    expect(service).toContain(".eq('policy_version', requiredPolicyVersion)")
    expect(service).toContain("evidence['user_id'] != user.id")
    expect(service).toContain("evidence['checkbox_acknowledged'] != true")
    expect(service).toContain("evidence['checkbox_acknowledged_at']")
  })

  it('requires migration approval and never fabricates legacy checkbox evidence', () => {
    expect(sql).toContain('REVIEW ONLY: NOT A MIGRATION')
    expect(sql).toContain('checkbox_acknowledged boolean')
    expect(sql).toContain('checkbox_acknowledged_at timestamptz')
    expect(sql).toContain('new.checkbox_acknowledged_at := now()')
    expect(sql).toContain("new.decision = 'accepted'")
    expect(sql).toContain('Legacy accepted rows with no checkbox evidence stay NULL')
    expect(sql).not.toMatch(/\bupdate\s+public\.policy_acceptances\s+set\b/i)
  })
})
