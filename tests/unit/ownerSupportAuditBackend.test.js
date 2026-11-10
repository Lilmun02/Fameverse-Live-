import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const api = readFileSync(new URL('../../api/owner/console.js', import.meta.url), 'utf8')
const schema = readFileSync(new URL('../../docs/staged-owner-support-audit-read-foundation.sql', import.meta.url), 'utf8')

describe('Owner support and audit backend staging contract', () => {
  it('uses existing support intake but never claims unseen RLS-protected rows are empty', () => {
    expect(api).toContain("from('owner_cases')")
    expect(api).toContain("from('beta_feedback')")
    expect(api).toContain("eq('current_screen', 'web_support')")
    expect(api).toContain("availability: 'requires_isolated_backend'")
  })
  it('never fabricates audit events or mutates production for preview actions', () => {
    expect(api).toContain("from('owner_audit_events')")
    expect(api).toContain("applied: false, recorded: false, mode: 'preview'")
    expect(schema).toContain('REVIEW-ONLY PROPOSAL')
    expect(schema).not.toMatch(/\b(?:stripe_checkout|checkout_session|payment_intent)\b/i)
  })
  it('locks access to owner role and read-only grants on both new stores', () => {
    expect(schema).toContain('enable row level security;')
    expect(schema).toContain('r.role = \'owner\'')
    expect(schema).toContain('grant select on public.owner_cases to authenticated;')
    expect(schema).toContain('grant select on public.owner_audit_events to authenticated;')
    expect(schema).not.toContain('grant insert')
    expect(schema).not.toContain('grant update')
    expect(schema).not.toContain('grant delete')
  })
})
