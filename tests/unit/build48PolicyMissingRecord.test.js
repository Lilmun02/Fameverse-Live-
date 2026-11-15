import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const sql = readFileSync(
  new URL('../../supabase/migrations/20261115_build48_policy_missing_record_failclosed.sql', import.meta.url),
  'utf8',
)
const statements = sql.replace(/--.*$/gm, '')

describe('Build 48 policy guard fails closed without an acceptance record', () => {
  it('authorizes only an existing account-bound decision', () => {
    expect(statements).toContain('and exists (')
    expect(statements).toContain('from public.policy_acceptances as p')
    expect(statements).toContain('p.user_id = (select auth.uid())')
    expect(statements).toContain("p.policy_version = '2026-10'")
    expect(statements).not.toContain('not exists (')
  })

  it('only accepts explicit server-stored agreement for restricted features', () => {
    expect(statements).toContain("p.decision = 'accepted'")
    expect(statements).not.toContain("p.decision = 'unsigned'")
    expect(statements).not.toContain("p.notice_started_at + interval '10 days'")
    expect(statements).not.toContain('insert into')
    expect(statements).not.toContain('delete from')
    expect(statements).not.toContain('update public.')
  })

  it('does not bypass RLS or modify unrelated functionality', () => {
    expect(statements).toContain('security invoker')
    expect(statements).not.toContain('security definer')
    expect(statements).not.toContain('grant execute')
    expect(statements).not.toContain('live_tap_batches')
    expect(statements).not.toContain('gift_events')
    expect(statements).not.toContain('wallet')
  })
})
