import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const sql=readFileSync(new URL('../../docs/owner-command-execution-review.sql',import.meta.url),'utf8')
describe('Staged Owner Command execution approval boundaries',()=>{
  it('is not a production migration and restricts direct RPC execution to service role',()=>{
    expect(sql).toContain('REVIEW ONLY; NOT A DEPLOYABLE MIGRATION')
    expect(sql).toContain('to service_role;')
    expect(sql).toContain('from public, anon, authenticated;')
    expect(sql).toContain('Verified owner required')
    expect(sql).toContain('Owner cannot review own account')
    expect(sql).toContain('Cannot moderate another owner')
  })
  it('records each applied command atomically and prevents duplicate execution',()=>{
    expect(sql).toContain('pg_advisory_xact_lock')
    expect(sql).toContain('p_idempotency_key')
    expect(sql).toContain('Idempotency key reused with different command')
    expect(sql).toContain('public.owner_audit_events')
    expect(sql).toContain("'applied', true, 'recorded', true")
  })
  it('supports narrow audited verification and support operations only',()=>{
    expect(sql).toContain("p_operation in ('approve_badge', 'reject_badge')")
    expect(sql).toContain("p_operation = 'review_support'")
    expect(sql).toContain('Pending creator verification request not found')
    expect(sql).toContain('Reviewable support case not found')
    expect(sql).not.toMatch(/\b(?:stripe_checkout|checkout_session|purchase_webhook|update public\.coin|update public\.creator_payout_requests)\b/i)
  })
})
