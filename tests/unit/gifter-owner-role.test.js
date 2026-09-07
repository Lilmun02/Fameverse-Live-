import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'

function read(path) {
  return readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8')
}

describe('owner gifter identity lock', () => {
  it('uses an authoritative role source and never shows regular gifter badges to privileged identities', () => {
    const roles = read('src/services/accountRoles.js')
    const profile = read('src/components/profile/ProfileView.jsx')
    const liveProfile = read('src/components/live/LiveProfileSheet.jsx')
    const liveProfileData = read('src/services/profiles.js')
    const migration = read('supabase/migrations/20260906_add_account_roles.sql')

    expect(roles).toMatch(/\.from\('account_roles'\)/)
    expect(roles).toMatch(/'owner', 'admin'/)
    expect(profile).toMatch(/isPrivilegedIdentityRole\(profile\?\.account_role\)/)
    expect(profile).toMatch(/totalCoinsSent > 0 && !hideGifterBadge/)
    expect(liveProfileData).toMatch(/accountRole/)
    expect(liveProfile).toMatch(/isPrivilegedIdentityRole\(profile\?\.accountRole\)/)
    expect(liveProfile).toMatch(/profile\.totalCoinsSent > 0 && !hideGifterBadge/)
    expect(migration).toMatch(/revoke insert, update, delete[\s\S]*from anon, authenticated/)
    expect(migration).toMatch(/grant select[\s\S]*to anon, authenticated/)
  })
})
