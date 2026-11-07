function nonemptyText(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null
}

export function webAccountIdentity(account) {
  if (!account.authReady) return { state: 'checking' }
  const user = account.session?.user
  if (!user?.id) return { state: 'guest' }
  const profile = account.profile?.id === user.id ? account.profile : null
  const email = nonemptyText(user.email)
  const displayName = nonemptyText(profile?.display_name) || nonemptyText(user.user_metadata?.display_name) || email?.split('@')[0] || 'Your account'
  const username = nonemptyText(profile?.username)
  return {
    state: 'signed-in',
    displayName,
    initial: Array.from(displayName)[0]?.toUpperCase() || 'F',
    handle: username ? `@${username}` : null,
    avatarUrl: nonemptyText(profile?.avatar_url),
    email,
    profileLoading: !profile,
  }
}
