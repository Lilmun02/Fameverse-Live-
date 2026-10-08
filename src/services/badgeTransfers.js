import { supabase } from './supabase.js'

// Only the native mobile app submits a claim. The website provides OWNER review.
export async function loadOwnerBadgeTransferQueue() {
  const { data, error } = await supabase
    .from('badge_transfer_claims')
    .select('id,user_id,source_platform,source_username,source_level,status,approved_level,evidence_path,review_note,submitted_at')
    .in('status', ['pending', 'needs_info'])
    .order('submitted_at', { ascending: true })
    .limit(60)

  if (error) return { claims: [], error: error.message }

  const claims = data || []
  const userIds = [...new Set(claims.map((item) => item.user_id).filter(Boolean))]
  if (!userIds.length) return { claims, error: null }

  const { data: profiles, error: profileError } = await supabase
    .from('profiles')
    .select('id,display_name,username')
    .in('id', userIds)
  const profilesById = new Map((profiles || []).map((p) => [p.id, p]))
  return {
    claims: claims.map((claim) => ({
      ...claim,
      applicant: profilesById.get(claim.user_id) || null,
    })),
    error: profileError ? 'Applicant names are temporarily unavailable.' : null,
  }
}

export async function getBadgeProofUrl(evidencePath) {
  const { data, error } = await supabase.storage
    .from('badge-transfer-proofs')
    .createSignedUrl(evidencePath, 180)
  if (error) throw error
  return data?.signedUrl
}

export async function decideBadgeTransfer({
  claimId,
  decision,
  approvedLevel = null,
  note = '',
}) {
  if (!['approved', 'needs_info', 'rejected'].includes(decision)) {
    throw new Error('Unknown transfer review decision.')
  }
  const level = approvedLevel === null || approvedLevel === ''
    ? null
    : Number(approvedLevel)
  if (decision === 'approved' &&
      (!Number.isInteger(level) || level < 5 || level > 25)) {
    throw new Error('Invalid calculated badge transfer level.')
  }
  const { data, error } = await supabase.rpc('owner_review_badge_transfer', {
    p_claim_id: claimId,
    p_decision: decision,
    p_approved_level: decision === 'approved' ? level : null,
    p_note: String(note || '').slice(0, 1000),
  })
  if (error) throw error
  return data
}
