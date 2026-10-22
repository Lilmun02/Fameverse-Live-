export function seekGiftThumbnail(event, seconds = 0) {
  const video = event.currentTarget
  if (!Number.isFinite(seconds) || seconds <= 0) return
  try { video.currentTime = seconds } catch {}
}

export function videoConstraints(facingMode = 'user') {
  return {
    facingMode: { ideal: facingMode },
    width: { ideal: 1280 },
    height: { ideal: 720 },
  }
}

/**
 * Ask the authenticated backend before a NEW Live starts. This deliberately
 * leaves End Live available even when policy eligibility changes mid-stream.
 */
export async function mayStartPolicyGatedLive({ enabled, alreadyLive, rpc, onDenied }) {
  if (!enabled || alreadyLive) return true
  try {
    const { data, error } = await rpc('fv_policy_permissions')
    if (!error && data?.can_go_live === true) return true
    onDenied('Accept Fameverse policies before going Live')
    return false
  } catch {
    onDenied('Could not verify Go Live eligibility · please retry')
    return false
  }
}
