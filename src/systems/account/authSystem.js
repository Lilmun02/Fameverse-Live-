import { supabase } from '../../services/supabase.js'

export async function getCurrentSession() {
  const { data } = await supabase.auth.getSession()
  return data.session
}

export function subscribeToAuthChanges(onSessionChange) {
  const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
    onSessionChange(nextSession)
  })
  return () => data.subscription.unsubscribe()
}

export function signUpWithEmail({ email, password, displayName }) {
  return supabase.auth.signUp({
    email: email.trim(),
    password,
    options: { data: { display_name: displayName.trim() || 'Fameverse User' } },
  })
}

export function signInWithEmail({ email, password }) {
  return supabase.auth.signInWithPassword({ email: email.trim(), password })
}

export function signOutAccount() {
  return supabase.auth.signOut()
}
