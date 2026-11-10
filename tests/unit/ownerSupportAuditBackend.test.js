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
    expect(schema).toContain('grant select, insert, update on public.owner_cases to service_role;')
    expect(schema).toContain('grant select, insert on public.owner_audit_events to service_role;')
    expect(schema).not.toMatch(/grant\\s+(?:insert|update|delete)[^;]*to\\s+authenticated/i)
    expect(schema).not.toMatch(/grant\\s+(?:insert|update|delete)[^;]*to\\s+anon/i)
  })
  it('keeps owner audit records append-only and links real support intake to cases', () => {
    expect(schema).toContain('owner_audit_immutable_before_change')
    expect(schema).toContain('before update or delete on public.owner_audit_events')
    expect(schema).toContain('owner_case_from_feedback_after_insert')
    expect(schema).toContain("if new.current_screen = 'web_support'")
    expect(schema).toContain('on conflict (source_feedback_id) do nothing')
    expect(schema).toContain("where f.current_screen = 'web_support'")
    expect(schema).not.toContain('new.message')
  })
})
