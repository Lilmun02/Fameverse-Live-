import { createClient } from '@supabase/supabase-js'
import { configuredOwnerGate, ownerCodeMatches, ownerIPAllowed, trustedRequestIP } from '../../src/server/ownerSecurity.mjs'

const BACKEND_URL = 'https://lwasmvzsagowgmiqssph.supabase.co'
const BACKEND_PUBLISHABLE_KEY = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'
const SUMMARY_FIELDS = [
  'reward_reserve_cents',
  'cash_backed_coins_outstanding',
  'creator_earnings_unpaid_cents',
  'platform_share_earned_cents',
]

function reply(res, status, payload) {
  res.setHeader('Cache-Control', 'private, no-store, max-age=0')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-Robots-Tag', 'noindex, nofollow')
  return res.status(status).json(payload)
}

export default async function ownerControl(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST')
    return reply(res, 405, { error: 'Method not allowed' })
  }

  // Nothing is served until both the code hash and an exact IP allowlist exist.
  const gate = configuredOwnerGate()
  if (!gate) return reply(res, 503, { error: 'Owner access is not configured' })
  if (!ownerIPAllowed(gate, trustedRequestIP(req.headers))) {
    return reply(res, 403, { error: 'Access denied' })
  }

  // Explicit origin check: the protected endpoint is intended for same-origin web only.
  let origin
  try { origin = new URL(String(req.headers.origin || '')) }
  catch { return reply(res, 403, { error: 'Access denied' }) }
  if (origin.protocol !== 'https:' || origin.host !== req.headers.host) {
    return reply(res, 403, { error: 'Access denied' })
  }

  const authHeader = String(req.headers.authorization || '')
  const token = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(authHeader)?.[1]
  if (!token) return reply(res, 403, { error: 'Access denied' })

  const body = req.body && typeof req.body === 'object' ? req.body : {}
  if (body.action !== 'summary') return reply(res, 400, { error: 'Unsupported owner action' })

  try {
    const client = createClient(BACKEND_URL, BACKEND_PUBLISHABLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    })
    const { data: auth, error: authError } = await client.auth.getUser(token)
    if (authError || !auth?.user?.id) return reply(res, 403, { error: 'Access denied' })

    const { data: accountRole, error: roleError } = await client
      .from('account_roles').select('role').eq('user_id', auth.user.id).maybeSingle()
    if (roleError || accountRole?.role !== 'owner') {
      return reply(res, 403, { error: 'Access denied' })
    }

    if (!ownerCodeMatches(gate, body.code)) {
      return reply(res, 403, { error: 'Access denied' })
    }

    // Existing DB function also independently checks auth.uid() has the owner role.
    const { data, error } = await client.rpc('get_owner_finance_control_summary')
    const row = Array.isArray(data) ? data[0] : data
    if (error || !row) return reply(res, 503, { error: 'Owner summary is unavailable' })
    const summary = Object.fromEntries(SUMMARY_FIELDS.map((key) => [key, row[key] ?? null]))
    return reply(res, 200, { authorized: true, mode: 'read-only', summary })
  } catch {
    return reply(res, 503, { error: 'Owner access is temporarily unavailable' })
  }
}
