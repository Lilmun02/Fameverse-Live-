import { describe, expect, it } from 'vitest'
import { webAccountIdentity } from '../../src/utils/webAccountIdentity.js'

describe('web-only account identity display', () => {
  it('does not call a pending auth restoration signed out', () => {
    expect(webAccountIdentity({ authReady: false })).toEqual({ state: 'checking' })
  })
  it('shows guest after sign-out even when a previous profile still exists', () => {
    expect(webAccountIdentity({ authReady: true, session: null, profile: { id: 'old', display_name: 'Old profile' } })).toEqual({ state: 'guest' })
  })
  it('shows only the current session profile and real handle', () => {
    const value = webAccountIdentity({ authReady: true, session: { user: { id: 'current', email: 'current@example.test' } }, profile: { id: 'current', display_name: 'Current Creator', username: 'currentcreator', avatar_url: 'https://example.test/avatar.png' } })
    expect(value).toMatchObject({ state: 'signed-in', displayName: 'Current Creator', handle: '@currentcreator', initial: 'C', profileLoading: false })
  })
  it('never renders a prior account profile during an account switch', () => {
    const value = webAccountIdentity({ authReady: true, session: { user: { id: 'new', email: 'new@example.test' } }, profile: { id: 'old', display_name: 'Old Creator', username: 'oldcreator', avatar_url: 'https://example.test/old.png' } })
    expect(value).toMatchObject({ state: 'signed-in', displayName: 'new', handle: null, avatarUrl: null, profileLoading: true })
  })
  it('uses real session metadata while a profile is loading, not a fake handle', () => {
    const value = webAccountIdentity({ authReady: true, session: { user: { id: 'current', email: 'email@example.test', user_metadata: { display_name: 'Actual Name' } } }, profile: null })
    expect(value.displayName).toBe('Actual Name')
    expect(value.handle).toBeNull()
  })
  it('handles malformed optional metadata safely without replacing authentication', () => {
    const value = webAccountIdentity({ authReady: true, session: { user: { id: 'current', email: 'safe@example.test', user_metadata: { display_name: { invalid: true } } } } })
    expect(value).toMatchObject({ state: 'signed-in', displayName: 'safe', initial: 'S' })
  })
})
