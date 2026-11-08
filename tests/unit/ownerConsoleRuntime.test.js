import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ createClient:vi.fn(),getUser:vi.fn(),role:vi.fn(),rpc:vi.fn(),members:vi.fn(),live:vi.fn(),from:vi.fn() }))
vi.mock('@supabase/supabase-js',()=>({
  createClient:(...args)=>{
    mocks.createClient(...args)
    return {
      auth:{getUser:mocks.getUser},
      from:(table)=>{
        mocks.from(table)
        if(table==='account_roles')return {select:()=>({eq:()=>({maybeSingle:mocks.role})})}
        const value=table==='profiles' ? mocks.members : mocks.live
        const chain={select:()=>chain,order:()=>chain,ilike:()=>chain,eq:()=>chain,
          limit:()=>Promise.resolve({data:[],error:null}),range:()=>value()}
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
  it('fetches real authorized member records',async()=>{
    const r=response()
    await ownerConsole(request({action:'read',section:'users',query:'creator'}),r)
    expect(r.code, JSON.stringify(r.body)).toBe(200)
    expect(r.body.items[0].username).toBe('creator')
    expect(r.body.items[0]).not.toHaveProperty('email')
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
  it('does not invent support, audit and system records',async()=>{
    for(const section of ['support','audit','system']){
      const r=response()
      await ownerConsole(request({action:'read',section}),r)
      expect(r.code, JSON.stringify(r.body)).toBe(200)
      expect(r.body.availability).toBe('requires_isolated_backend')
    }
  })
})
