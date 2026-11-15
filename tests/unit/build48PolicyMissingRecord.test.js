import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const sql = readFileSync(
  new URL('../../supabase/migrations/20261115_build48_policy_missing_record_failclosed.sql', import.meta.url),
  'utf8',
)

describe('Build 48 policy guard fails closed without an acceptance record', () => {
  it('authorizes only an existing account-bound decision', () => {
    expect(sql).toContain('and exists (')
    expect(sql).toContain('from public.policy_acceptances as p')
    expect(sql).toContain('p.user_id = (select auth.uid())')
    expect(sql).toContain("p.policy_version = '2026-10'")
    expect(sql).not.toContain('not exists (')
  })

  it('preserves accepted access and original 10-day notice/grace deadline', () => {
    expect(sql).toContain("p.decision = 'accepted'")
    expect(sql).toContain("p.decision = 'unsigned'")
    expect(sql).toContain("p.notice_started_at + interval '10 days'")
    expect(sql).not.toContain('insert into')
    expect(sql).not.toContain('delete from')
    expect(sql).not.toContain('update public.')
  })

  it('does not bypass RLS or modify unrelated functionality', () => {
    expect(sql).toContain('security invoker')
    expect(sql).not.toContain('security definer')
    expect(sql).not.toContain('grant execute')
    expect(sql).not.toContain('live_tap_batches')
    expect(sql).not.toContain('gift_events')
    expect(sql).not.toContain('wallet')
  })
})
