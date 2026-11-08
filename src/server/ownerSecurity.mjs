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

export function recentlyPasswordSignedIn(claims, nowSeconds = Math.floor(Date.now() / 1000)) {
  return Boolean(claims && claims.is_anonymous !== true && Array.isArray(claims.amr) &&
    claims.amr.some(entry => entry.method === 'password' && Number.isFinite(entry.timestamp) &&
      entry.timestamp <= nowSeconds && entry.timestamp >= nowSeconds - 600))
}

// A Magic Link MUST NOT count as the owner's separately entered numeric email code.
export function recentlyEmailCodeVerified(claims, nowSeconds = Math.floor(Date.now() / 1000)) {
  return Boolean(claims && claims.is_anonymous !== true && Array.isArray(claims.amr) &&
    claims.amr.some(entry => entry.method === 'otp' && Number.isFinite(entry.timestamp) &&
      entry.timestamp <= nowSeconds && entry.timestamp >= nowSeconds - 600))
}
