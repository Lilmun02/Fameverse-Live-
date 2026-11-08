import { isIP } from 'node:net'

// The only configuration is an explicit server-side IP allowlist.
// Never accept an IP supplied in a request body or browser storage.
export function configuredOwnerGate(env = process.env) {
  const allowedIPs = String(env.OWNER_ALLOWED_IPS || '')
    .split(',').map((entry) => entry.trim()).filter(Boolean)
  if (allowedIPs.length !== 1 || !allowedIPs.every((ip) => isIP(ip) !== 0)) return null
  return { allowedIPs }
}

export function trustedRequestIP(headers) {
  const value = headers?.['x-vercel-forwarded-for']
  if (typeof value !== 'string' || value.includes(',')) return null
  const ip = value.trim()
  return isIP(ip) !== 0 ? ip : null
}

export function ownerIPAllowed(config, ip) {
  return Boolean(config && ip && config.allowedIPs.includes(ip))
}

// An email-confirmed account alone does not satisfy the fresh email step.
// Require a verified Supabase JWT showing a recent OTP / email-link login.
// The server must call auth.getClaims(token), never trust client-provided claims.
export function recentlyEmailVerified(claims, nowSeconds = Math.floor(Date.now() / 1000)) {
  if (!claims || claims.is_anonymous === true || !Array.isArray(claims.amr)) return false
  return claims.amr.some((entry) =>
    ['otp', 'magiclink'].includes(entry?.method) &&
    Number.isFinite(entry?.timestamp) &&
    entry.timestamp <= nowSeconds &&
    entry.timestamp >= nowSeconds - 10 * 60
  )
}
