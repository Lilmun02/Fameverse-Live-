import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

// Build 47 contract only: this test never connects to Supabase and never
// touches wallets, purchases, checkout sessions or actual gifting data.
const sql = readFileSync(
  new URL('../../supabase/migrations/20261105_build47_utc_rankings_top100.sql', import.meta.url),
  'utf8',
)

function branchSql(kind, following) {
  const start = sql.indexOf(`if v_kind = '${kind}' then`)
  const end = following ? sql.indexOf(`if v_kind = '${following}' then`, start) : sql.indexOf("raise exception 'unsupported ranking kind'", start)
  expect(start).toBeGreaterThan(-1)
  expect(end).toBeGreaterThan(start)
  return sql.slice(start, end)
}

describe('Build 47 UTC ranking backend regression contract', () => {
  it('resets daily at 00:00 UTC and weekly on Sunday at 00:00 UTC', () => {
    expect(sql).toContain("when '24h' then date_trunc('day', now() at time zone 'UTC') at time zone 'UTC'")
    expect(sql).toContain("when 'daily' then date_trunc('day', now() at time zone 'UTC') at time zone 'UTC'")
    expect(sql).toContain("when '7d' then (date_trunc('week', (now() at time zone 'UTC') + interval '1 day') - interval '1 day') at time zone 'UTC'")
    expect(sql).toContain("when 'weekly' then (date_trunc('week', (now() at time zone 'UTC') + interval '1 day') - interval '1 day') at time zone 'UTC'")
    expect(sql).toContain('least(coalesce(p_limit, 100), 100)')
  })

  it('Supporters measures cash-backed gifting and excludes self- and promo-only gifts', () => {
    const section = branchSql('supporters', 'pulse')
    expect(section).toContain('public.gift_events')
    expect(section).toContain('public.gift_funding_breakdowns')
    expect(section).toContain('f.cash_backed_coins > 0')
    expect(section).toContain('g.sender_user_id <> g.recipient_user_id')
    expect(section).toContain('t.ranked_score > 0')
    expect(section).not.toContain('public.live_tap_batches')
  })

  it('Pulse scores eligible Fame taps, not purchase or gifting events', () => {
    const section = branchSql('pulse', 'creators')
    expect(section).toContain('public.live_tap_batches')
    expect(section).toContain('b.eligible_tap_count')
    expect(section).toContain('t.ranked_score > 0')
    expect(section).not.toContain('public.gift_events')
  })

  it('Creators require positive eligible host taps and show follower count as secondary', () => {
    const section = branchSql('creators')
    expect(section).toContain('public.live_rooms')
    expect(section).toContain('b.room_id = lr.id')
    expect(section).toContain('b.eligible_tap_count')
    expect(section).toContain('t.ranked_score > 0')
    expect(section).toContain('follower_count')
    expect(section).toContain('coalesce(f.follower_count, 0)::bigint')
  })

  it('is an authenticated read-only ranking function with no purchase mutations', () => {
    expect(sql).toContain('if auth.uid() is null then')
    expect(sql).toContain('to authenticated;')
    expect(sql).toContain('to service_role;')
    expect(sql).not.toMatch(/^\s*(?:insert|update|delete|truncate)\b/im)
    expect(sql).not.toMatch(/\b(?:stripe|checkout_session|payment_intent|purchase_webhook)\b/i)
  })
})
