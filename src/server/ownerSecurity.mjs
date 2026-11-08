import { isIP } from 'node:net'

// Fail closed: exactly one valid, Vercel Preview branch-scoped public IP.
// Neither request parameters nor the browser can add an allowed address.
export function configuredOwnerGate(env = process.env) {
  const allowedIPs = String(env.OWNER_ALLOWED_IPS || '')
    .split(',').map(ip => ip.trim()).filter(Boolean)
  if (allowedIPs.length !== 1 || isIP(allowedIPs[0]) === 0) return null
  return { allowedIPs }
}

export function trustedRequestIP(headers) {
  // Vercel documents this header as its forwarded client IP. Reject an
  // ambiguous chain, missing header or malformed IP instead of guessing.
  const value = headers?.['x-vercel-forwarded-for']
  if (typeof value !== 'string' || value.includes(',')) return null
  const ip = value.trim()
  return isIP(ip) ? ip : null
}

export function ownerIPAllowed(gate, requestIP) {
  return Boolean(gate && requestIP && gate.allowedIPs.includes(requestIP))
}
