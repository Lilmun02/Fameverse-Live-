import { supabase } from './supabase.js'

const PRIVILEGED_IDENTITY_ROLES = new Set(['owner', 'admin'])

export function isPrivilegedIdentityRole(role) {
  return PRIVILEGED_IDENTITY_ROLES.has(String(role || '').trim().toLowerCase())
}

export async function loadAccountRole(userId) {
  if (!userId) return null

  const { data, error } = await supabase
    .from('account_roles')
    .select('role')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  return data?.role || null
}
