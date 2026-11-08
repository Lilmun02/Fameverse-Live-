import { createClient } from '@supabase/supabase-js'
import { configuredOwnerGate, ownerCodeMatches, ownerIPAllowed, trustedRequestIP, prepareOwnerGateMaterial } from '../../src/server/ownerSecurity.mjs'

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
  // Public readiness is the only information returned by GET.
  // Never ask anyone for an access code until owner-controlled setup exists.
  if (req.method === 'GET') {
    return reply(res, 200, { configured: Boolean(configuredOwnerGate()) })
  }
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'GET, POST')
    return reply(res, 405, { error: 'Method not allowed' })
  }

  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {}
  if (body.action !== 'summary' && body.action !== 'prepare') {
    return reply(res, 400, { error: 'Unsupported owner action' })
  }

  // Exact-origin verification before any credential work.
  let origin
  try { origin = new URL(String(req.headers.origin || '')) }
  catch { return reply(res, 403, { error: 'Access denied' }) }
  if (origin.protocol !== 'https:' || origin.host !== req.headers.host) {
    return reply(res, 403, { error: 'Access denied' })
  }

  const authHeader = String(req.headers.authorization || '')
  const token = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(authHeader)?.[1]
  if (!token) return reply(res, 403, { error: 'Access denied' })

  const gate = configuredOwnerGate()
  const sourceIP = trustedRequestIP(req.headers)
  if (body.action === 'summary') {
    if (!gate) return reply(res, 503, { error: 'Owner access is not configured' })
    if (!ownerIPAllowed(gate, sourceIP)) return reply(res, 403, { error: 'Access denied' })
  } else if (gate) {
    // Setup cannot overwrite or reset existing access credentials.
    return reply(res, 409, { error: 'Owner access is already configured' })
  }

  try {
    // Use verified Supabase auth and the existing owner role; no service role.
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

    if (body.action === 'prepare') {
      if (!sourceIP) {
        return reply(res, 422, { error: 'Approved IP could not be detected. Setup remains locked.' })
      }
      const prepared = prepareOwnerGateMaterial(body.code, sourceIP)
      if (!prepared) {
        return reply(res, 400, { error: 'Choose a security code between 16 and 128 characters.' })
      }
      // Hash + salt are setup values only; owner must store them privately in Vercel.
      // No plaintext code is returned, logged, stored or added to the repository.
      return reply(res, 200, { prepared: true, ...prepared })
    }

    if (!ownerCodeMatches(gate, body.code)) {
      return reply(res, 403, { error: 'Access denied' })
    }

    // Existing RPC independently verifies auth.uid() is the owner.
    const { data, error } = await client.rpc('get_owner_finance_control_summary')
    const row = Array.isArray(data) ? data[0] : data
    if (error || !row) return reply(res, 503, { error: 'Owner summary is unavailable' })
    const summary = Object.fromEntries(SUMMARY_FIELDS.map((key) => [key, row[key] ?? null]))
    return reply(res, 200, { authorized: true, mode: 'read-only', summary })
  } catch {
    return reply(res, 503, { error: 'Owner access is temporarily unavailable' })
  }
}
