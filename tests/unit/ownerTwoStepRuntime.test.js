import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ createClient:vi.fn(),getUser:vi.fn(),role:vi.fn(),rpc:vi.fn() }))
vi.mock('@supabase/supabase-js',()=>({
  createClient: (...args) => {
    mocks.createClient(...args)
    return {
      auth:{getUser:mocks.getUser},
      from:()=>({select:()=>({eq:()=>({maybeSingle:mocks.role})})}),
      rpc:mocks.rpc,
    }
  },
}))
import ownerControl from '../../api/owner/control.js'
function request(headers = {}, action = 'summary') {
  return { method:'POST',body:{action},headers:{
    host:'preview.example',origin:'https://preview.example',
    authorization:'Bearer valid.owner.jwt',
    'x-vercel-forwarded-for':'203.0.113.8',
    ...headers,
  }}
}
function res() {return { code:null,body:null,headers:{},
  setHeader(k,v){this.headers[k]=v;return this},
  status(c){this.code=c;return this},json(b){this.body=b;return this},
}}
beforeEach(()=>{
  vi.resetAllMocks()
  vi.stubEnv('OWNER_ALLOWED_IPS','203.0.113.8')
  mocks.getUser.mockResolvedValue({data:{user:{id:'owner-id',email:'owner@example.test',email_confirmed_at:'2026-11-01T00:00:00Z'}},error:null})
  mocks.role.mockResolvedValue({data:{role:'owner'},error:null})
  mocks.rpc.mockResolvedValue({data:{
    reward_reserve_cents:5000,cash_backed_coins_outstanding:2400,
    creator_earnings_unpaid_cents:1600,platform_share_earned_cents:400,
    private_secret:'do not return',
  },error:null})
})
afterEach(()=>vi.unstubAllEnvs())
describe('owner access: existing account AND approved IP',()=>{
  it('blocks wrong IP before calling Supabase',async()=>{
    const r=res()
    await ownerControl(request({'x-vercel-forwarded-for':'203.0.113.9'}),r)
    expect(r.code).toBe(403)
    expect(r.body.code).toBe('NETWORK_DENIED')
    expect(r.body.summary).toBeUndefined()
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('blocks missing or spoofed forwarded IP headers',async()=>{
    const r=res()
    await ownerControl(request({'x-vercel-forwarded-for':'203.0.113.8, 203.0.113.9'}),r)
    expect(r.code).toBe(403)
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('blocks all calls when IP is unconfigured',async()=>{
    vi.stubEnv('OWNER_ALLOWED_IPS','')
    const r=res()
    await ownerControl(request(),r)
    expect(r.code).toBe(503)
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('does not expose public GET readiness or owner data',async()=>{
    const r=res()
    await ownerControl({...request(),method:'GET'},r)
    expect(r.code).toBe(405)
    expect(r.body.summary).toBeUndefined()
    expect(r.headers.Allow).toBe('POST')
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('requires same-origin HTTPS requests',async()=>{
    const r=res()
    await ownerControl(request({origin:'https://evil.example'}),r)
    expect(r.code).toBe(403)
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('rejects requests without a valid bearer token',async()=>{
    const r=res()
    await ownerControl(request({authorization:'garbage'}),r)
    expect(r.code).toBe(403)
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('rejects invalid or expired Supabase sessions',async()=>{
    mocks.getUser.mockResolvedValue({data:{user:null},error:{message:'Invalid JWT'}})
    const r=res()
    await ownerControl(request(),r)
    expect(r.code).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('rejects unconfirmed email accounts',async()=>{
    mocks.getUser.mockResolvedValue({data:{user:{id:'owner-id',email:'owner@example.test',email_confirmed_at:null}},error:null})
    const r=res()
    await ownerControl(request(),r)
    expect(r.code).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('rejects accounts without authoritative owner role',async()=>{
    mocks.role.mockResolvedValue({data:{role:'member'},error:null})
    const r=res()
    await ownerControl(request(),r)
    expect(r.code).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('returns only read-only whitelisted fields after authorized owner checks',async()=>{
    const r=res()
    await ownerControl(request(),r)
    expect(r.code).toBe(200)
    expect(r.body.authorized).toBe(true)
    expect(r.body.mode).toBe('read-only')
    expect(r.body.summary.reward_reserve_cents).toBe(5000)
    expect(r.body.summary.private_secret).toBeUndefined()
    expect(r.headers['Cache-Control']).toContain('no-store')
    expect(mocks.rpc).toHaveBeenCalledWith('get_owner_finance_control_summary')
  })
  it('opens management access without requiring the financial RPC', async () => {
    mocks.rpc.mockRejectedValue(new Error('Finance RPC unavailable'))
    const response=res()
    await ownerControl(request({}, 'access'), response)
    expect(response.code).toBe(200)
    expect(response.body).toEqual({authorized:true,mode:'owner-access'})
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
})
