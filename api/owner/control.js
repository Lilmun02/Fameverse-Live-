import { createClient } from '@supabase/supabase-js'
import { configuredOwnerGate, ownerIPAllowed, trustedRequestIP } from '../../src/server/ownerSecurity.mjs'

const BACKEND_URL = 'https://lwasmvzsagowgmiqssph.supabase.co'
const BACKEND_PUBLISHABLE_KEY = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'
const SUMMARY_FIELDS = [
  'reward_reserve_cents',
  'cash_backed_coins_outstanding',
  'creator_earnings_unpaid_cents',
  'platform_share_earned_cents',
]

function reply(res, status, data) {
  res.setHeader('Cache-Control', 'private, no-store, max-age=0')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-Robots-Tag', 'noindex, nofollow')
  return res.status(status).json(data)
}

// All owner API requests require the same exact approved source IP.
// No alternate access via a client-provided IP, email link, or security code.
export default async function ownerControl(req, res) {
  const gate = configuredOwnerGate()
  if (!gate) return reply(res, 503, { error: 'Owner IP restriction is not configured' })
  if (!ownerIPAllowed(gate, trustedRequestIP(req.headers))) {
    return reply(res, 403, { error: 'Owner network not approved', code: 'NETWORK_DENIED' })
  }

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST')
    return reply(res, 405, { error: 'Method not allowed' })
  }
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {}
  if (body.action !== 'summary' && body.action !== 'access') {
    return reply(res, 400, { error: 'Unsupported owner action' })
  }

  let origin
  try { origin = new URL(String(req.headers.origin || '')) }
  catch { return reply(res, 403, { error: 'Access denied' }) }
  if (origin.protocol !== 'https:' || origin.host !== req.headers.host) {
    return reply(res, 403, { error: 'Access denied' })
  }

  const token = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(String(req.headers.authorization || ''))?.[1]
  if (!token) return reply(res, 403, { error: 'Fameverse sign-in required' })

  try {
    const client = createClient(BACKEND_URL, BACKEND_PUBLISHABLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    })
    // Supabase Auth verifies the token remotely. No trust in session.user from
    // the browser or user-editable metadata.
    const { data: auth, error: authError } = await client.auth.getUser(token)
    if (authError || !auth?.user?.id || !auth.user.email || !auth.user.email_confirmed_at) {
      return reply(res, 403, { error: 'Verified Fameverse account required' })
    }

    // Existing authoritative roles table; the API never trusts client role text.
    const { data: role, error: roleError } = await client.from('account_roles')
      .select('role').eq('user_id', auth.user.id).maybeSingle()
    if (roleError || role?.role !== 'owner') {
      return reply(res, 403, { error: 'Owner account required' })
    }

    // Access must not depend on financial RPC availability; management and
    // moderation pages can still load if the finance summary is unavailable.
    if (body.action === 'access') {
      return reply(res, 200, { authorized: true, mode: 'owner-access' })
    }

    // Existing read-only RPC also independently enforces the owner role.
    const { data, error } = await client.rpc('get_owner_finance_control_summary')
    const row = Array.isArray(data) ? data[0] : data
    if (error || !row) return reply(res, 503, { error: 'Owner overview unavailable' })
    return reply(res, 200, {
      authorized: true,
      mode: 'read-only',
      summary: Object.fromEntries(SUMMARY_FIELDS.map((field) => [field, row[field] ?? null])),
    })
  } catch {
    return reply(res, 503, { error: 'Owner access temporarily unavailable' })
  }
}
