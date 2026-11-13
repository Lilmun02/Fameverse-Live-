import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ createClient:vi.fn(),getUser:vi.fn(),role:vi.fn(),rpc:vi.fn(),members:vi.fn(),live:vi.fn(),from:vi.fn(),gte:vi.fn(),eq:vi.fn(),cases:vi.fn(),support:vi.fn(),audit:vi.fn() }))
vi.mock('@supabase/supabase-js',()=>({
  createClient:(...args)=>{
    mocks.createClient(...args)
    return {
      auth:{getUser:mocks.getUser},
      from:(table)=>{
        mocks.from(table)
        if(table==='account_roles')return {select:()=>({eq:()=>({maybeSingle:mocks.role})})}
        const value=table==='profiles' ? mocks.members :
          table==='owner_cases' ? mocks.cases :
          table==='beta_feedback' ? mocks.support :
          table==='owner_audit_events' ? mocks.audit : mocks.live
        const chain={select:()=>chain,order:()=>chain,ilike:()=>chain,in:()=>chain,eq:(field,value)=>{mocks.eq(table,field,value);return chain},
          gte:(field,value)=>{mocks.gte(table,field,value);return chain},
          limit:()=>table==='owner_cases' ? value() : Promise.resolve({data:[],error:null}),range:()=>value(),
          then:(resolve,reject)=>Promise.resolve({data:[],count:0,error:null}).then(resolve,reject)}
        return chain
      },
      rpc:mocks.rpc,
    }
  },
}))
import ownerConsole from '../../api/owner/console.js'
function request(body, headers={}) {
  return {method:'POST',body,headers:{origin:'https://preview.example',host:'preview.example',
    authorization:'Bearer verified.owner.token','x-vercel-forwarded-for':'203.0.113.8',...headers}}
}
function response() {
  return {code:null,body:null,headers:{},
    setHeader(k,v){this.headers[k]=v;return this},
    status(c){this.code=c;return this},
    json(b){this.body=b;return this}}
}
beforeEach(()=>{
  vi.resetAllMocks()
  vi.stubEnv('OWNER_ALLOWED_IPS','203.0.113.8')
  mocks.getUser.mockResolvedValue({data:{user:{id:'11111111-1111-4111-8111-111111111111',email:'owner@example.test',email_confirmed_at:'2026-11-01'}},error:null})
  mocks.role.mockResolvedValue({data:{role:'owner'},error:null})
  mocks.rpc.mockResolvedValue({data:[{reward_reserve_cents:1000}],error:null})
  mocks.members.mockResolvedValue({data:[{id:'22222222-2222-4222-8222-222222222222',username:'creator',display_name:'Creator'}],count:1,error:null})
  mocks.live.mockResolvedValue({data:[],count:0,error:null})
  mocks.cases.mockResolvedValue({data:null,error:{message:'unavailable'}})
  mocks.support.mockResolvedValue({data:[],count:0,error:null})
  mocks.audit.mockResolvedValue({data:null,count:null,error:{message:'unavailable'}})
})
afterEach(()=>vi.unstubAllEnvs())
describe('Owner Command Center protected operations',()=>{
  it('rejects wrong IP before any user lookup',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'users'},{'x-vercel-forwarded-for':'203.0.113.9'}),r)
    expect(r.code).toBe(403)
    expect(r.body.code).toBe('NETWORK_DENIED')
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('rejects non-owner accounts for every section',async()=>{
    mocks.role.mockResolvedValue({data:{role:'member'},error:null})
    const r=response()
    await ownerConsole(request({action:'read',section:'users'}),r)
    expect(r.code).toBe(403)
    expect(mocks.members).not.toHaveBeenCalled()
  })
  it('rejects unknown sections and unsupported methods',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'drop_table'}),r)
    expect(r.code, JSON.stringify(r.body)).toBe(400)
    const g=response()
    await ownerConsole({...request({action:'read',section:'users'}),method:'GET'},g)
    expect(g.code).toBe(405)
  })
  it('excludes stale live rooms using the same 45-second heartbeat threshold as live presence',async()=>{
    const started=Date.now()
    const r=response()
    await ownerConsole(request({action:'read',section:'live'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    const filters=mocks.gte.mock.calls.filter(([table,field])=>table==='live_rooms'&&field==='heartbeat_at')
    expect(filters).toHaveLength(1)
    const expiry=Date.parse(filters[0][2])
    expect(expiry).toBeGreaterThanOrEqual(started-45000)
    expect(expiry).toBeLessThanOrEqual(Date.now()-45000)
  })
  it('uses the same live heartbeat cutoff for the owner overview count',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'overview'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    expect(mocks.gte).toHaveBeenCalledWith('live_rooms','heartbeat_at',expect.any(String))
    expect(r.body.live).toBe(0)
  })
  it('fetches real authorized member records',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'users',query:'creator'}),r)
    expect(r.code, JSON.stringify(r.body)).toBe(200)
    expect(r.body.items[0].username).toBe('creator')
    expect(r.body.items[0]).not.toHaveProperty('email')
  })
  it('locks actual owner control execution until a separately approved server rollout',async()=>{
    const r=response()
    await ownerConsole(request({action:'execute_action',operation:'approve_badge',
      targetId:'22222222-2222-4222-8222-222222222222',
      reason:'Verified supporting creator evidence.',confirmed:true,
      idempotencyKey:'77777777-7777-4777-8777-777777777777'}),r)
    expect(r.code).toBe(409)
    expect(r.body.code).toBe('OWNER_WRITE_INACTIVE')
    expect(mocks.createClient).toHaveBeenCalledTimes(1)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('never executes high-risk payouts, gift grants, live moderation, or system operations through phase one',async()=>{
    vi.stubEnv('FAMEVERSE_OWNER_COMMANDS_ENABLED','verified-v1')
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY','test-only-internal-key')
    for(const operation of ['ban','end_live','release_payout','grant_test_coins','allocate_reserve','system_maintenance']){
      const r=response()
      await ownerConsole(request({action:'execute_action',operation,
        targetId:'22222222-2222-4222-8222-222222222222',
        reason:'Documented review evidence for owner.',confirmed:true,
        idempotencyKey:'77777777-7777-4777-8777-777777777777'}),r)
      expect(r.code,operation).toBe(409)
      expect(r.body.code).toBe('OWNER_OPERATION_UNAVAILABLE')
    }
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('requires explicit confirmation and an idempotency key before an active badge change',async()=>{
    vi.stubEnv('FAMEVERSE_OWNER_COMMANDS_ENABLED','verified-v1')
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY','test-only-internal-key')
    const r=response()
    await ownerConsole(request({action:'execute_action',operation:'approve_badge',
      targetId:'22222222-2222-4222-8222-222222222222',
      reason:'Documented verified creator evidence.'}),r)
    expect(r.code).toBe(400)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('accepts an active action only when server RPC confirms both application and audit',async()=>{
    vi.stubEnv('FAMEVERSE_OWNER_COMMANDS_ENABLED','verified-v1')
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY','test-only-internal-key')
    mocks.rpc.mockResolvedValueOnce({data:{applied:true,recorded:true,auditId:'99999999-9999-4999-8999-999999999999'},error:null})
    const r=response()
    await ownerConsole(request({action:'execute_action',operation:'approve_badge',
      targetId:'22222222-2222-4222-8222-222222222222',
      reason:'Documented verified creator evidence.',confirmed:true,
      idempotencyKey:'77777777-7777-4777-8777-777777777777'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    expect(r.body).toMatchObject({authorized:true,applied:true,recorded:true})
    expect(mocks.rpc).toHaveBeenCalledWith('owner_apply_control_v1',expect.objectContaining({
      p_operation:'approve_badge',p_target_id:'22222222-2222-4222-8222-222222222222',
      p_actor_user_id:'11111111-1111-4111-8111-111111111111',
      p_idempotency_key:'77777777-7777-4777-8777-777777777777',
    }))
    expect(r.body).not.toHaveProperty('SUPABASE_SERVICE_ROLE_KEY')
  })
  it('fails closed if an active backend call cannot confirm the durable audit',async()=>{
    vi.stubEnv('FAMEVERSE_OWNER_COMMANDS_ENABLED','verified-v1')
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY','test-only-internal-key')
    mocks.rpc.mockResolvedValueOnce({data:{applied:true,recorded:false},error:null})
    const r=response()
    await ownerConsole(request({action:'execute_action',operation:'review_support',
      targetId:'22222222-2222-4222-8222-222222222222',
      reason:'Documented support case follow-up.',confirmed:true,
      idempotencyKey:'77777777-7777-4777-8777-777777777777'}),r)
    expect(r.code).toBe(503)
    expect(r.body.code).toBe('OWNER_COMMAND_UNCONFIRMED')
  })
  it('validates commands but does not mutate production',async()=>{
    const r=response()
    await ownerConsole(request({action:'preview_action',operation:'allocate_reserve',reason:'Review reserve coverage before approval.'}),r)
    expect(r.code, JSON.stringify(r.body)).toBe(200)
    expect(r.body.mode).toBe('preview')
    expect(r.body.applied).toBe(false)
    expect(r.body.recorded).toBe(false)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('rejects missing reason and missing target UUIDs',async()=>{
    const a=response(),b=response()
    await ownerConsole(request({action:'preview_action',operation:'ban',reason:'bad'}),a)
    await ownerConsole(request({action:'preview_action',operation:'ban',reason:'Review repeated policy violations.'}),b)
    expect(a.code, JSON.stringify(a.body)).toBe(400)
    expect(b.code, JSON.stringify(b.body)).toBe(400)
  })
  it('does not permit owner self-enforcement',async()=>{
    const r=response()
    await ownerConsole(request({action:'preview_action',operation:'permanent_ban',
      targetId:'11111111-1111-4111-8111-111111111111',reason:'Review repeated policy violations.'}),r)
    expect(r.code, JSON.stringify(r.body)).toBe(400)
  })
  it('does not validate enforcement when RLS hides the target role',async()=>{
    mocks.role.mockResolvedValueOnce({data:{role:'owner'},error:null})
      .mockResolvedValueOnce({data:null,error:null})
    const r=response()
    await ownerConsole(request({action:'preview_action',operation:'suspend',
      targetId:'22222222-2222-4222-8222-222222222222',reason:'Review the reported account evidence.'}),r)
    expect(r.code).toBe(400)
    expect(r.body.error).toBe('Privileged-role verification required before this action')
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('only validates an explicitly verified non-owner target, without executing a write',async()=>{
    mocks.role.mockResolvedValueOnce({data:{role:'owner'},error:null})
      .mockResolvedValueOnce({data:{role:'member'},error:null})
    const r=response()
    await ownerConsole(request({action:'preview_action',operation:'suspend',
      targetId:'22222222-2222-4222-8222-222222222222',reason:'Review the reported account evidence.'}),r)
    expect(r.code).toBe(200)
    expect(r.body).toMatchObject({applied:false,recorded:false,mode:'preview'})
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('reads release state without exposing any system mutation endpoint',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'system'}),r)
    expect(r.code).toBe(200)
    expect(r.body.authorized).toBe(true)
    expect(r.body.items).toEqual([])
    expect(mocks.from).toHaveBeenCalledWith('app_release_state')
  })
  it('uses the existing authorized catalog RPC rather than the RLS-blocked gift table',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'gifts'}),r)
    expect(r.code).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('get_fameverse_gift_catalog')
    expect(mocks.from).not.toHaveBeenCalledWith('fameverse_gift_catalog')
  })
  it('routes Pulse, Supporters and Creators to their distinct authoritative ranking categories',async()=>{
    for (const kind of ['pulse','supporters','creators']) {
      mocks.rpc.mockClear()
      const r=response()
      await ownerConsole(request({action:'read',section:'reports',kind,window:'weekly'}),r)
      expect(r.code,JSON.stringify(r.body)).toBe(200)
      expect(mocks.rpc).toHaveBeenCalledWith('get_fameverse_rankings_v2',{
        p_kind:kind,p_window:'7d',p_limit:20,
      })
    }
  })
  it('does not allow unrecognized ranking categories to flow into the backend RPC',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'reports',kind:'invented',window:'daily'}),r)
    expect(r.code).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('get_fameverse_rankings_v2',{
      p_kind:'creators',p_window:'24h',p_limit:20,
    })
  })
  it('loads payout queue and real finance totals from independent owner RPCs',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'finance'}),r)
    expect(r.code).toBe(200)
    expect(mocks.rpc).toHaveBeenCalledWith('get_creator_payout_moderation_queue_v3',{p_limit:25})
    expect(mocks.rpc).toHaveBeenCalledWith('get_owner_finance_control_summary')
    expect(r.body).toHaveProperty('summary')
  })
  it('does not treat RLS-hidden support records as an empty owner inbox',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'support'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    expect(r.body.availability).toBe('requires_isolated_backend')
    expect(mocks.from).not.toHaveBeenCalledWith('beta_feedback')
  })
  it('lists existing web support intake only after protected owner schema is available',async()=>{
    mocks.cases.mockResolvedValue({data:[],error:null})
    mocks.support.mockResolvedValue({data:[{id:'22222222-2222-4222-8222-222222222222',
      user_id:'33333333-3333-4333-8333-333333333333',
      category:'other',message:'Help with my account',created_at:'2026-11-10T12:00:00Z'}],count:1,error:null})
    const r=response()
    await ownerConsole(request({action:'read',section:'support'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    expect(r.body.source).toBe('verified_web_feedback')
    expect(r.body.items).toHaveLength(1)
    expect(r.body.total).toBe(1)
    expect(mocks.from).toHaveBeenCalledWith('beta_feedback')
  })
  it('lists persistent audit records only when the protected table is accessible',async()=>{
    mocks.audit.mockResolvedValue({data:[{id:'44444444-4444-4444-8444-444444444444',
      section:'moderation',operation:'warn',outcome:'applied'}],count:1,error:null})
    const r=response()
    await ownerConsole(request({action:'read',section:'audit'}),r)
    expect(r.code,JSON.stringify(r.body)).toBe(200)
    expect(r.body.source).toBe('protected_owner_audit')
    expect(r.body.items).toHaveLength(1)
    expect(r.body.total).toBe(1)
  })
  it('does not invent support or audit records',async()=>{
    for(const section of ['support','audit']){
      const r=response()
      await ownerConsole(request({action:'read',section}),r)
      expect(r.code, JSON.stringify(r.body)).toBe(200)
      expect(r.body.availability).toBe('requires_isolated_backend')
    }
  })
})


describe('Owner case and audit cross-section filters', () => {
  const caseId='55555555-5555-4555-8555-555555555555'
  const targetId='66666666-6666-4666-8666-666666666666'
  it('passes case and subject filters to protected support intake', async () => {
    mocks.cases.mockResolvedValue({data:[],error:null})
    const r=response()
    await ownerConsole(request({action:'read',section:'support',caseId,targetId}),r)
    expect(r.code).toBe(200)
    expect(mocks.eq).toHaveBeenCalledWith('beta_feedback','case.id',caseId)
    expect(mocks.eq).toHaveBeenCalledWith('beta_feedback','user_id',targetId)
  })
  it('filters durable audit events by actual case and target IDs', async () => {
    mocks.audit.mockResolvedValue({data:[],count:0,error:null})
    const r=response()
    await ownerConsole(request({action:'read',section:'audit',caseId,targetId}),r)
    expect(r.code).toBe(200)
    expect(mocks.eq).toHaveBeenCalledWith('owner_audit_events','case_id',caseId)
    expect(mocks.eq).toHaveBeenCalledWith('owner_audit_events','target_id',targetId)
    expect(r.body.source).toBe('protected_owner_audit')
  })
  it('rejects malformed filters instead of silently returning unrelated records', async () => {
    const r=response()
    await ownerConsole(request({action:'read',section:'audit',caseId:'not-a-case'}),r)
    expect(r.code).toBe(400)
    expect(mocks.from).not.toHaveBeenCalled()
  })
  it('rejects a revoked role before reading any of the thirteen sections', async () => {
    mocks.role.mockResolvedValue({data:{role:'member'},error:null})
    for(const section of ['overview','users','live','moderation','gifts','finance','funding','reports','badges','support','policy','system','audit']){
      const r=response()
      await ownerConsole(request({action:'read',section}),r)
      expect(r.code,section).toBe(403)
    }
    expect(mocks.from.mock.calls.every(([table])=>table==='account_roles')).toBe(true)
  })
})


describe('Staged moderation case read',()=>{
 it('never substitutes member profiles when the case store is unavailable',async()=>{
  const r=response()
  await ownerConsole(request({action:'read',section:'moderation'}),r)
  expect(r.code).toBe(200)
  expect(r.body.availability).toBe('requires_isolated_backend')
  expect(mocks.from).not.toHaveBeenCalledWith('profiles')
 })
 it('returns authorized case rows with shared case and subject filters',async()=>{
  const caseId='55555555-5555-4555-8555-555555555555'
  const subject='66666666-6666-4666-8666-666666666666'
  mocks.cases.mockResolvedValue({data:[{id:caseId,subject_user_id:subject,status:'under_review',case_type:'moderation',summary:'Reported conduct'}],count:1,error:null})
  const r=response()
  await ownerConsole(request({action:'read',section:'moderation',caseId,targetId:subject}),r)
  expect(r.body.source).toBe('protected_owner_cases')
  expect(r.body.items[0].id).toBe(caseId)
  expect(mocks.eq).toHaveBeenCalledWith('owner_cases','id',caseId)
  expect(mocks.eq).toHaveBeenCalledWith('owner_cases','subject_user_id',subject)
 })
})
