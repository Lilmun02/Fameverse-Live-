import { describe, expect, it } from 'vitest'
import { suggestedTransferLevel, MAX_IMPORTED_RECOGNITION_LEVEL } from '../../src/features/badges/transferConversion.js'
import { readFileSync } from 'node:fs'

describe('Fameverse draft imported badge recognition policy', () => {
  it.each([
    ['tiktok', 5, 7],
    ['tiktok', 15, 11],
    ['favorited', 25, 15],
    ['favorited', 38, 20],
    ['tiktok', 50, 25],
    ['epic', 80, 25],
    ['epic', 99, 25],
  ])('%s badge %i converts to capped recognition %i', (platform, level, expected) => {
    expect(suggestedTransferLevel(platform, level)).toBe(expected)
  })

  it('cannot import invalid or unapproved sources and levels', () => {
    expect(suggestedTransferLevel('echo', 15)).toBe(null)
    expect(suggestedTransferLevel('tiktok', 80)).toBe(null)
    expect(suggestedTransferLevel('epic', 0)).toBe(null)
    expect(suggestedTransferLevel('favorited', 100)).toBe(null)
    expect(suggestedTransferLevel('favorited', 1.5)).toBe(null)
    expect(MAX_IMPORTED_RECOGNITION_LEVEL).toBe(25)
  })

  it('enforces the conversion server-side and never credits coins or spend', () => {
    const sql = readFileSync(
      new URL('../../supabase/migrations/20261007_badge_transfer_owner_review.sql', import.meta.url),
      'utf8',
    )
    const owner = readFileSync(
      new URL('../../src/components/owner/OwnerBadgeTransfers.jsx', import.meta.url),
      'utf8',
    )

    expect(sql).toContain('create or replace function public.calculate_badge_transfer_level')
    expect(sql).toContain('least(25, 5 + floor(p_source_level::numeric * 2 / 5)::integer)')
    expect(sql).toContain('p_approved_level <> v_transfer_level')
    expect(sql).toContain('approved_level = v_transfer_level')
    expect(sql).toContain("source_platform <> 'tiktok' or source_level <= 50")
    expect(sql).not.toMatch(/update public\.gifter_stats/i)
    expect(sql).not.toMatch(/update public\.coin_funding_balances/i)
    expect(owner).toContain('suggestedTransferLevel(claim.source_platform, claim.source_level)')
    expect(owner).toContain('Capped at Lv. 25.')
  })
})
