import { createClient } from '@supabase/supabase-js'
import { configuredOwnerGate, ownerIPAllowed, recentlyPasswordSignedIn, recentlyEmailCodeVerified, trustedRequestIP } from '../../src/server/ownerSecurity.mjs'

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

export default async function ownerControl(req, res) {
  if (req.method === 'GET') {
    // No authenticated owner information is returned by public readiness.
    return reply(res, 200, { configured: Boolean(configuredOwnerGate()) })
  }
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'GET, POST')
    return reply(res, 405, { error: 'Method not allowed' })
  }
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {}
  if (body.action !== 'status' && body.action !== 'summary') {
    return reply(res, 400, { error: 'Unsupported owner action' })
  }

  let origin
  try { origin = new URL(String(req.headers.origin || '')) }
  catch { return reply(res, 403, { error: 'Access denied' }) }
  if (origin.protocol !== 'https:' || origin.host !== req.headers.host) {
    return reply(res, 403, { error: 'Access denied' })
  }

  const token = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(String(req.headers.authorization || ''))?.[1]
  if (!token) return reply(res, 403, { error: 'Access denied' })

  // Deny summary requests immediately if no IP allowlist exists or source IP
  // does not match. No secret, role data, or financial data leaves the server.
  const gate = configuredOwnerGate()
  const requestIP = trustedRequestIP(req.headers)
  const emailOtpReady = process.env.OWNER_EMAIL_OTP_ENABLED === 'true'
  if (body.action === 'summary' && !ownerIPAllowed(gate, requestIP)) {
    return reply(res, 403, { error: 'Owner network not approved' })
  }

  try {
    const client = createClient(BACKEND_URL, BACKEND_PUBLISHABLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    })
    const { data: auth, error: authError } = await client.auth.getUser(token)
    if (authError || !auth?.user?.id || !auth.user.email || !auth.user.email_confirmed_at) {
      return reply(res, 403, { error: 'Verified Fameverse email sign-in required' })
    }

    const { data: role, error: roleError } = await client.from('account_roles')
      .select('role').eq('user_id', auth.user.id).maybeSingle()
    if (roleError || role?.role !== 'owner') {
      return reply(res, 403, { error: 'Owner access denied' })
    }

    // Verify both factors independently against Supabase Auth, with matching
    // user IDs. Client-side session flags and ordinary magic links never count.
    const { data: claimResult, error: claimError } = await client.auth.getClaims(token)
    const claims = !claimError && claimResult?.claims?.sub === auth.user.id ? claimResult.claims : null
    const emailVerifiedRecently = recentlyEmailCodeVerified(claims)
    let passwordVerifiedRecently = recentlyPasswordSignedIn(claims)

    const proofToken = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(
      String(req.headers['x-owner-password-proof'] || '')
    )?.[1]
    if (proofToken && proofToken !== token) {
      const [proofIdentity, proofClaims] = await Promise.all([
        client.auth.getUser(proofToken),
        client.auth.getClaims(proofToken),
      ])
      passwordVerifiedRecently = !proofIdentity.error && !proofClaims.error &&
        proofIdentity.data?.user?.id === auth.user.id &&
        proofIdentity.data?.user?.email === auth.user.email &&
        proofClaims.data?.claims?.sub === auth.user.id &&
        recentlyPasswordSignedIn(proofClaims.data.claims)
    }

    if (body.action === 'status') {
      return reply(res, 200, {
        verifiedAccount: true,
        ipConfigured: Boolean(gate),
        ipApproved: ownerIPAllowed(gate, requestIP),
        observedIP: requestIP,
        emailOtpReady,
        passwordVerifiedRecently,
        emailVerifiedRecently,
      })
    }
    if (!emailOtpReady) {
      return reply(res, 503, { error: 'Owner email-code verification is not activated' })
    }
    if (!passwordVerifiedRecently || !emailVerifiedRecently) {
      return reply(res, 403, { error: 'Fresh password and email-code verification required' })
    }

    // Existing server-side RPC independently enforces auth.uid() = owner.
    const { data, error } = await client.rpc('get_owner_finance_control_summary')
    const row = Array.isArray(data) ? data[0] : data
    if (error || !row) return reply(res, 503, { error: 'Owner summary unavailable' })
    return reply(res, 200, {
      authorized: true,
      mode: 'read-only',
      summary: Object.fromEntries(SUMMARY_FIELDS.map((name) => [name, row[name] ?? null])),
    })
  } catch {
    return reply(res, 503, { error: 'Owner access temporarily unavailable' })
  }
}
