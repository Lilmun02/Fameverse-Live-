import { scryptSync, timingSafeEqual } from 'node:crypto'
import { isIP } from 'node:net'

// Server-only owner checks. No browser import and no authorization from user metadata.
export function configuredOwnerGate(env = process.env) {
  const allowedIPs = String(env.OWNER_ALLOWED_IPS || '')
    .split(',').map((entry) => entry.trim()).filter(Boolean)
  const salt = String(env.OWNER_ACCESS_CODE_SALT || '')
  const hash = String(env.OWNER_ACCESS_CODE_SCRYPT_HASH || '').toLowerCase()
  if (!allowedIPs.length || !allowedIPs.every((ip) => isIP(ip) !== 0)) return null
  if (salt.length < 16 || !/^[0-9a-f]{128}$/.test(hash)) return null
  return { allowedIPs, salt, hash }
}

export function trustedRequestIP(headers) {
  const header = headers?.['x-vercel-forwarded-for']
  if (typeof header !== 'string' || header.includes(',')) return null
  const ip = header.trim()
  return isIP(ip) ? ip : null
}

export function ownerIPAllowed(config, requestIP) {
  return Boolean(config && requestIP && config.allowedIPs.includes(requestIP))
}

export function ownerCodeMatches(config, code) {
  if (!config || typeof code !== 'string' || code.length < 12 || code.length > 128) return false
  try {
    const digest = scryptSync(code, config.salt, 64)
    const expected = Buffer.from(config.hash, 'hex')
    return expected.length === digest.length && timingSafeEqual(expected, digest)
  } catch {
    return false
  }
}
