import { createClient } from '@supabase/supabase-js'
import { randomUUID } from 'node:crypto'
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
  const r = await client.from('live_rooms')
    .select('id,host_user_id,title,status,started_at,heartbeat_at,created_at', { count: 'exact' })
    .eq('status', 'live').order('started_at', { ascending: false }).range(start, end)
  return { items: checked(r, 'Live rooms'), total: r.count ?? null, page }
}

async function ownerSummary(client) {
  const [finance, countUsers, countLive] = await Promise.all([
    client.rpc('get_owner_finance_control_summary'),
    client.from('profiles').select('id', { count: 'exact', head: true }),
    client.from('live_rooms').select('id', { count: 'exact', head: true }).eq('status','live'),
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
    const r = await client.rpc('get_creator_payout_moderation_queue_v3',{ p_limit: 25 })
    return { items: checked(r, 'Payout review'), total: null }
  }
  if (name === 'badges') {
    const r = await client.rpc('get_creator_verification_moderation_queue',{ p_limit: 25 })
    return { items: checked(r, 'Verification queue'), total: null }
  }
  return { items: [], total: 0 }
}

async function fetchRead(client, section, body) {
  switch(section) {
    case 'overview': return ownerSummary(client)
    case 'users': return listProfiles(client, body)
    case 'moderation': return listProfiles(client, body)
    case 'live': return listLive(client, body)
    case 'badges': return ownerQueue(client, 'badges')
    case 'finance': return ownerQueue(client, 'finance')
    case 'funding': {
      const r = await client.rpc('get_owner_reward_control_summary')
      return { summary: flat(checked(r, 'Owner funding summary')) }
    }
    case 'gifts': {
      const r = await client.from('fameverse_gift_catalog')
        .select('id,label,cost_coins,category,active,cinematic,sort_order')
        .order('sort_order', { ascending: true }).limit(100)
      return { items: checked(r, 'Gift catalog') }
    }
    case 'policy': {
      const r = await client.from('app_update_notices')
        .select('id,update_type,title,summary,published_at,active,requires_acknowledgement')
        .eq('active', true).order('published_at', { ascending: false }).limit(25)
      return { items: checked(r, 'Published notices') }
    }
    case 'reports': {
      const r = await client.rpc('get_fameverse_rankings_v2',{
        p_kind: body.kind === 'supporters' ? 'supporters' : 'creators',
        p_window: ['daily','weekly','all_time'].includes(body.window) ? body.window : 'daily',
        p_limit: 20,
      })
      return { items: checked(r, 'Rankings report') }
    }
    case 'support':
      return { availability: 'requires_isolated_backend', message: 'Support inbox needs an owner-only read policy and audited case workflow. Preview is connected to the production database; no unapproved policy changes were made.' }
    case 'audit':
      return { availability: 'requires_isolated_backend', message: 'Persistent owner audit log needs a protected case and audit table. No fabricated log entries are shown.' }
    case 'system':
      return { availability: 'requires_isolated_backend', message: 'Release management and system updates require an audited, separately approved backend.' }
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
    if (r.error || r.data?.role === 'owner') return { error: 'Privileged-role verification required before this action' }
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
