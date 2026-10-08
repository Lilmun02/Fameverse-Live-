import { supabase } from './supabase.js'

function firstRow(data) {
  return Array.isArray(data) ? data[0] || null : data || null
}

export async function loadOwnerRewardSummary() {
  const { data, error } = await supabase.rpc('get_owner_reward_control_summary')
  if (error) throw error
  return firstRow(data)
}

export async function loadMyCashRewardPermission() {
  const { data, error } = await supabase.rpc('get_my_cash_reward_permission')
  if (error) throw error
  return firstRow(data) || {
    cash_rewards_enabled: false,
    max_gross_cents_per_gift: 100,
  }
}

export async function allocateRewardReserve(amountCents, note = '') {
  const { data, error } = await supabase.rpc('owner_allocate_reward_reserve', {
    p_amount_cents: amountCents,
    p_note: note || null,
  })
  if (error) throw error
  return Number(data || 0)
}

export async function setStaffCashRewardPermission({ userId, enabled, maxGrossCentsPerGift }) {
  const { data, error } = await supabase.rpc('owner_set_staff_cash_reward', {
    p_user_id: userId,
    p_enabled: Boolean(enabled),
    p_max_gross_cents_per_gift: maxGrossCentsPerGift,
  })
  if (error) throw error
  return firstRow(data)
}

export async function listOwnerOperators() {
  const { data: roles, error: roleError } = await supabase
    .from('account_roles')
    .select('user_id, role')
    .in('role', ['owner', 'admin'])
  if (roleError) throw roleError

  const ids = (roles || []).map((row) => row.user_id).filter(Boolean)
  if (!ids.length) return []

  const [{ data: profiles, error: profileError }, { data: permissions, error: permissionError }] = await Promise.all([
    supabase.from('profiles').select('id, display_name, username, avatar_url').in('id', ids),
    supabase.from('staff_cash_reward_permissions').select('user_id, cash_rewards_enabled, max_gross_cents_per_gift').in('user_id', ids),
  ])
  if (profileError) throw profileError
  if (permissionError) throw permissionError

  const profilesById = new Map((profiles || []).map((row) => [row.id, row]))
  const permissionsById = new Map((permissions || []).map((row) => [row.user_id, row]))

  return (roles || []).map((roleRow) => ({
    ...roleRow,
    profile: profilesById.get(roleRow.user_id) || null,
    permission: permissionsById.get(roleRow.user_id) || {
      cash_rewards_enabled: false,
      max_gross_cents_per_gift: 100,
    },
  }))
}

export async function listPayoutQueue(limit = 50) {
  const { data, error } = await supabase.rpc('get_creator_payout_moderation_queue_v2', {
    p_limit: limit,
  })
  if (error) throw error
  return Array.isArray(data) ? data : []
}

export async function listVerificationQueue(limit = 50) {
  const { data, error } = await supabase.rpc('get_creator_verification_moderation_queue', {
    p_limit: limit,
  })
  if (error) throw error
  return Array.isArray(data) ? data : []
}

export async function reviewVerification({ userId, status, publicNote = null }) {
  const { data, error } = await supabase.rpc('review_creator_verification', {
    p_user_id: userId,
    p_status: status,
    p_public_note: publicNote,
  })
  if (error) throw error
  return data
}

export async function reviewPayout({ payoutId, status, note = null, externalReference = null }) {
  const { data, error } = await supabase.rpc('review_creator_payout', {
    p_payout_id: payoutId,
    p_status: status,
    p_moderation_note: note,
    p_external_reference: externalReference,
  })
  if (error) throw error
  return data
}

export async function releasePayout({ payoutId, expectedEnvironment = 'sandbox' }) {
  const { data, error } = await supabase.functions.invoke('process-creator-payout', {
    body: {
      payout_id: payoutId,
      expected_environment: expectedEnvironment,
    },
  })
  if (error) throw error
  if (data?.error) throw new Error(data.error)
  return data
}

export async function syncPayout({ payoutId, expectedEnvironment = 'sandbox' }) {
  const { data, error } = await supabase.functions.invoke('sync-creator-payout', {
    body: {
      payout_id: payoutId,
      expected_environment: expectedEnvironment,
    },
  })
  if (error) throw error
  if (data?.error) throw new Error(data.error)
  return data
}

export async function listActiveLives() {
  const { data: rooms, error: roomError } = await supabase
    .from('live_rooms')
    .select('id, host_user_id, title, status, started_at, ended_at')
    .eq('status', 'live')
    .is('ended_at', null)
    .order('started_at', { ascending: false })
  if (roomError) throw roomError

  const hostIds = [...new Set((rooms || []).map((room) => room.host_user_id).filter(Boolean))]
  if (!hostIds.length) return []

  const { data: profiles, error: profileError } = await supabase
    .from('profiles')
    .select('id, display_name, username, avatar_url')
    .in('id', hostIds)
  if (profileError) throw profileError

  const profilesById = new Map((profiles || []).map((profile) => [profile.id, profile]))
  return (rooms || []).map((room) => ({
    ...room,
    host: profilesById.get(room.host_user_id) || null,
  }))
}

export async function publishUpdateNotice({
  updateType,
  title,
  summary,
  changelog = [],
  requiresAcknowledgement = true,
}) {
  const { data, error } = await supabase.rpc('owner_publish_update_notice', {
    p_update_type: updateType,
    p_title: title,
    p_summary: summary,
    p_changelog: changelog,
    p_requires_acknowledgement: requiresAcknowledgement,
  })
  if (error) throw error
  return data
}
