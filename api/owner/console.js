import { createClient } from '@supabase/supabase-js'
import { randomUUID } from 'node:crypto'
import { LIVE_PRESENCE_STALE_MS } from '../../src/services/live/livePresenceConfig.js'
import { configuredOwnerGate, ownerIPAllowed, trustedRequestIP } from '../../src/server/ownerSecurity.mjs'

const SUPABASE_URL = 'https://lwasmvzsagowgmiqssph.supabase.co'
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC'
const READ_SECTIONS = new Set(['overview','users','live','moderation','gifts','finance','funding','reports','policy','system','audit','support','badges'])
const OPERATIONS = new Set([
  'warn','suspend','ban','permanent_ban','unban','kick_live','end_live','mute_live',
  'restrict','restore_access','review_activity','approve_badge','reject_badge',
  'hold_payout','release_payout','review_fraud','grant_test_coins','allocate_reserve',
  'publish_notice','staff_permission','system_maintenance','review_support',
])
const MAX_PAGE = 25

function reply(res, status, data) {
  res.setHeader('Cache-Control', 'private, no-store, max-age=0')
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-Robots-Tag', 'noindex, nofollow')
  return res.status(status).json(data)
}
function safeQuery(value) {
  return typeof value === 'string' ? value.trim().replace(/[^\p{L}\p{N}_ .-]/gu, '').slice(0, 64) : ''
}
function validId(value) {
  return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)
}
function pagination(body) {
  const page = Math.max(0, Math.min(200, Number.parseInt(body.page, 10) || 0))
  return { page, start: page * MAX_PAGE, end: page * MAX_PAGE + MAX_PAGE - 1 }
}
function checked(result, label) {
  if (result.error) throw new Error(label + ' unavailable')
  return result.data || []
}
function flat(row) { return Array.isArray(row) ? (row[0] || null) : (row || null) }

async function listProfiles(client, body) {
  const { page, start, end } = pagination(body)
  const q = safeQuery(body.query)
  let request = client.from('profiles')
    .select('id,username,display_name,avatar_url,created_at', { count: 'exact' })
    .order('created_at', { ascending: false })
  if (q) request = request.ilike('username', '%' + q + '%')
  const r = await request.range(start, end)
  return { items: checked(r, 'Member directory'), total: r.count ?? null, page, query: q }
}

async function listLive(client, body) {
  const { page, start, end } = pagination(body)
  // A status flag alone cannot prove a broadcast is still online.
  // Use exactly the same heartbeat expiry as the native live feed.
  const cutoff = new Date(Date.now() - LIVE_PRESENCE_STALE_MS).toISOString()
  const r = await client.from('live_rooms')
    .select('id,host_user_id,title,status,started_at,heartbeat_at,created_at', { count: 'exact' })
    .eq('status', 'live').gte('heartbeat_at', cutoff)
    .order('started_at', { ascending: false }).range(start, end)
  return { items: checked(r, 'Live rooms'), total: r.count ?? null, page }
}

async function ownerSummary(client) {
  const cutoff = new Date(Date.now() - LIVE_PRESENCE_STALE_MS).toISOString()
  const [finance, countUsers, countLive] = await Promise.all([
    client.rpc('get_owner_finance_control_summary'),
    client.from('profiles').select('id', { count: 'exact', head: true }),
    client.from('live_rooms').select('id', { count: 'exact', head: true })
      .eq('status', 'live').gte('heartbeat_at', cutoff),
  ])
  const warnings = []
  if (finance.error) warnings.push('Financial summary unavailable')
  if (countUsers.error) warnings.push('User count unavailable')
  if (countLive.error) warnings.push('Live count unavailable')
  return {
    overview: finance.error ? null : flat(finance.data),
    users: countUsers.error ? null : countUsers.count,
    live: countLive.error ? null : countLive.count,
    warnings,
  }
}

async function ownerQueue(client, name) {
  if (name === 'finance') {
    const [queue, summary] = await Promise.all([
      client.rpc('get_creator_payout_moderation_queue_v3',{ p_limit: 25 }),
      client.rpc('get_owner_finance_control_summary'),
    ])
    return {
      items: checked(queue, 'Payout review'), total: null,
      summary: summary.error ? null : flat(summary.data),
      warnings: summary.error ? ['Financial totals unavailable'] : [],
    }
  }
  if (name === 'badges') {
    const r = await client.rpc('get_creator_verification_moderation_queue',{ p_limit: 25 })
    return { items: checked(r, 'Verification queue'), total: null }
  }
  return { items: [], total: 0 }
}


// The support inbox already stores real intake in beta_feedback. Owner-wide
// access is NOT present in production RLS; require the reviewed case foundation
// before attempting to list it. Never mistake RLS-hidden rows for an empty inbox.
async function ownerSupport(client, body) {
  const { page, start, end } = pagination(body)
  const gate = await client.from('owner_cases').select('id', { head: true }).limit(1)
  if (gate.error) return {
    availability: 'requires_isolated_backend',
    message: 'The protected owner case schema and feedback read policy have not been deployed. No support records were guessed.',
  }
  const relation = body.caseId ? 'owner_cases!inner' : 'owner_cases'
  let query = client.from('beta_feedback')
    .select(`id,user_id,category,message,created_at,current_screen,case:${relation}(id,subject_user_id,case_type,status,summary,created_at,updated_at)`, { count: 'exact' })
    .eq('current_screen', 'web_support')
  if (body.caseId) query = query.eq('case.id', body.caseId)
  if (body.targetId) query = query.eq('user_id', body.targetId)
  const r = await query.order('created_at', { ascending: false }).order('id').range(start, end)
  if (r.error) return {
    availability: 'requires_isolated_backend',
    message: 'Owner support intake is inaccessible under current permissions. The inbox has not been declared empty.',
  }
  return { items: r.data || [], page, total: r.count ?? null, source: 'verified_web_feedback' }
}

// No browser-local or preview action history may masquerade as an audit log.
// Until the protected audit table is deployed, show a clear unavailable state.
async function ownerAudit(client, body) {
  const { page, start, end } = pagination(body)
  let query = client.from('owner_audit_events')
    .select('id,actor_user_id,case_id,section,operation,target_type,target_id,reason,outcome,created_at', { count: 'exact' })
  if (body.caseId) query = query.eq('case_id', body.caseId)
  if (body.targetId) query = query.eq('target_id', body.targetId)
  const r = await query.order('created_at', { ascending: false }).order('id').range(start, end)
  if (r.error) return {
    availability: 'requires_isolated_backend',
    message: 'Persistent owner audit storage has not been deployed. No preview history is presented as real audit evidence.',
  }
  return { items: r.data || [], page, total: r.count ?? null, source: 'protected_owner_audit' }
}

async function ownerModeration(client, body) {
  const { page, start, end } = pagination(body)
  let query = client.from('owner_cases')
    .select('id,source_feedback_id,subject_user_id,case_type,status,summary,created_at,updated_at', { count: 'exact' })
    .in('case_type', ['moderation','appeal','gift_integrity','policy','security'])
  const q = safeQuery(body.query)
  if (q) query = query.ilike('summary', '%' + q + '%')
  if (body.caseId) query = query.eq('id', body.caseId)
  if (body.targetId) query = query.eq('subject_user_id', body.targetId)
  const r = await query.order('created_at', { ascending: false }).order('id').range(start, end)
  if (r.error) return {
    availability:'requires_isolated_backend',
    message:'Protected moderation cases are not accessible. The staged case backend must be activated separately; the member directory is not an enforcement queue.',
  }
  return { items:r.data || [], page, total:r.count ?? null, source:'protected_owner_cases' }
}

async function fetchRead(client, section, body) {
  switch(section) {
    case 'overview': return ownerSummary(client)
    case 'users': return listProfiles(client, body)
    case 'moderation': return ownerModeration(client, body)
    case 'live': return listLive(client, body)
    case 'badges': return ownerQueue(client, 'badges')
    case 'finance': return ownerQueue(client, 'finance')
    case 'funding': {
      const r = await client.rpc('get_owner_reward_control_summary')
      return { summary: flat(checked(r, 'Owner funding summary')) }
    }
    case 'gifts': {
      // Direct table SELECT is not granted to authenticated. Reuse the
      // existing published read-only catalog RPC instead of weakening RLS.
      const r = await client.rpc('get_fameverse_gift_catalog')
      return { items: checked(r, 'Gift catalog'), activeOnly: true }
    }
    case 'policy': {
      const r = await client.from('app_update_notices')
        .select('id,update_type,title,summary,published_at,active,requires_acknowledgement')
        .eq('active', true).order('published_at', { ascending: false }).limit(25)
      return { items: checked(r, 'Published notices') }
    }
    case 'reports': {
      if (body.window === 'all_time') return {
        availability: 'requires_isolated_backend',
        message: 'All-time rankings need a separate verified backend query; the current ranking RPC only supports rolling 24-hour and 7-day windows.',
      }
      const r = await client.rpc('get_fameverse_rankings_v2',{
        p_kind: body.kind === 'supporters' ? 'supporters' : 'creators',
        p_window: body.window === 'weekly' ? '7d' : '24h',
        p_limit: 20,
      })
      return { items: checked(r, 'Rankings report'), windowType: 'rolling' }
    }
    case 'support': return ownerSupport(client, body)
    case 'audit': return ownerAudit(client, body)
    case 'system': {
      const r = await client.from('app_release_state')
        .select('channel,backend_revision,release_label,updated_at')
        .order('updated_at',{ascending:false}).limit(10)
      return {
        items: checked(r,'Release state'),
        message: 'Current release state is read-only. Publishing or changing releases requires audited approval.',
      }
    }
    default: return { availability: 'unavailable' }
  }
}

async function prepareAction(client, body, actorId) {
  const operation = typeof body.operation === 'string' ? body.operation : ''
  const note = typeof body.reason === 'string' ? body.reason.trim() : ''
  const targetId = typeof body.targetId === 'string' ? body.targetId : ''
  if (!OPERATIONS.has(operation)) return { error: 'Unsupported owner operation' }
  if (note.length < 12 || note.length > 600) return { error: 'Provide a reason between 12 and 600 characters' }
  if (!validId(targetId) && !['allocate_reserve','publish_notice','system_maintenance'].includes(operation)) {
    return { error: 'Select a valid target record' }
  }
  if (targetId === actorId && ['suspend','ban','permanent_ban','restrict','unban','restore_access'].includes(operation)) {
    return { error: 'Cannot enforce against the current owner session' }
  }
  if (validId(targetId) && ['ban','permanent_ban','suspend','restrict','unban','restore_access'].includes(operation)) {
    const r = await client.from('account_roles').select('role').eq('user_id',targetId).maybeSingle()
    // RLS only exposes the current owner's own role. Never pretend a missing
    // row proves the target is not another owner.
    if (r.error || !r.data?.role || r.data.role === 'owner') return { error: 'Privileged-role verification required before this action' }
  }
  return {
    id: randomUUID(), operation, targetId: targetId || null,
    reason: note, applied: false, recorded: false, mode: 'preview',
    message: 'Preview validation only. No account, live room, money, badge or database record was changed.',
  }
}

export default async function ownerConsole(req, res) {
  const gate = configuredOwnerGate()
  if (!gate) return reply(res, 503,{error:'Owner IP restriction is not configured'})
  if (!ownerIPAllowed(gate,trustedRequestIP(req.headers))) {
    return reply(res,403,{error:'Owner network not approved',code:'NETWORK_DENIED'})
  }
  if (req.method !== 'POST') {
    res.setHeader('Allow','POST')
    return reply(res,405,{error:'Method not allowed'})
  }
  let origin
  try { origin = new URL(String(req.headers.origin || '')) } catch { return reply(res,403,{error:'Access denied'}) }
  if (origin.protocol !== 'https:' || origin.host !== req.headers.host) return reply(res,403,{error:'Access denied'})
  const token = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(String(req.headers.authorization||''))?.[1]
  if (!token) return reply(res,403,{error:'Fameverse sign-in required'})
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {}
  if (!['read','preview_action'].includes(body.action)) return reply(res,400,{error:'Unsupported action'})
  if (body.action === 'read' && !READ_SECTIONS.has(body.section)) return reply(res,400,{error:'Unsupported section'})
  if (body.action === 'read' && ['caseId','targetId'].some(key => body[key] != null && body[key] !== '' && !validId(body[key]))) {
    return reply(res,400,{error:'Case and target filters must be valid UUIDs'})
  }

  try {
    const client = createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY,{
      auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false},
      global:{headers:{Authorization:`Bearer ${token}`}},
    })
    const {data: auth,error: authError} = await client.auth.getUser(token)
    if (authError || !auth?.user?.id || !auth.user.email || !auth.user.email_confirmed_at) {
      return reply(res,403,{error:'Verified Fameverse account required'})
    }
    const {data:role,error:roleError} = await client.from('account_roles').select('role').eq('user_id',auth.user.id).maybeSingle()
    if (roleError || role?.role !== 'owner') return reply(res,403,{error:'Owner account required'})

    if (body.action === 'preview_action') {
      const result = await prepareAction(client,body,auth.user.id)
      return result.error ? reply(res,400,{error:result.error}) : reply(res,200,{authorized:true,...result})
    }
    const result = await fetchRead(client,body.section,body)
    return reply(res,200,{authorized:true,section:body.section,...result})
  } catch {
    return reply(res,503,{error:'Protected owner records are temporarily unavailable'})
  }
}
