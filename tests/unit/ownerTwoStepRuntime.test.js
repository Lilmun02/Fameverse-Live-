import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  createClient: vi.fn(),
  getUser: vi.fn(),
  getClaims: vi.fn(),
  verifyOtp: vi.fn(),
  rpc: vi.fn(),
  role: vi.fn(),
}))

vi.mock('@supabase/supabase-js', () => ({
  createClient: (...args) => {
    mocks.createClient(...args)
    return {
      auth: { getUser: mocks.getUser, getClaims: mocks.getClaims, verifyOtp: mocks.verifyOtp },
      from: () => ({ select: () => ({ eq: () => ({ maybeSingle: mocks.role }) }) }),
      rpc: mocks.rpc,
    }
  },
}))

import ownerControl from '../../api/owner/control.js'

function req(action = 'summary', code = '123456', headers = {}) {
  return {
    method: 'POST',
    body: { action, code },
    headers: {
      origin: 'https://preview.example',
      host: 'preview.example',
      authorization: 'Bearer fresh.password.jwt',
      'x-vercel-forwarded-for': '203.0.113.8',
      ...headers,
    },
  }
}
function res() {
  return {
    code: null, body: null, headers: {},
    setHeader(k,v){this.headers[k]=v;return this},
    status(c){this.code=c;return this},
    json(b){this.body=b;return this},
  }
}

beforeEach(() => {
  vi.resetAllMocks()
  vi.stubEnv('OWNER_ALLOWED_IPS', '203.0.113.8')
  vi.stubEnv('OWNER_EMAIL_OTP_ENABLED', 'true')
  mocks.getUser.mockResolvedValue({
    data:{user:{id:'fameverse-owner-id',email:'verified@example.test',email_confirmed_at:'2026-11-08T12:00:00Z'}},error:null,
  })
  mocks.getClaims.mockResolvedValue({
    data:{claims:{sub:'fameverse-owner-id',is_anonymous:false,amr:[{method:'password',timestamp:Math.floor(Date.now()/1000)}]}},error:null,
  })
  mocks.role.mockResolvedValue({data:{role:'owner'},error:null})
  mocks.verifyOtp.mockResolvedValue({
    data:{user:{id:'fameverse-owner-id',email:'verified@example.test'},session:{access_token:'new-otp-session'}},error:null,
  })
  mocks.rpc.mockResolvedValue({
    data:{reward_reserve_cents:8400,cash_backed_coins_outstanding:1200,
      creator_earnings_unpaid_cents:450,platform_share_earned_cents:150,
      private_internal_secret:'must-not-escape'},error:null,
  })
})
afterEach(() => vi.unstubAllEnvs())

describe('Owner Vercel API authenticated OTP behavior', () => {
  it('denies unapproved networks without accessing any Supabase service', async () => {
    const response=res()
    await ownerControl(req('summary','123456',{'x-vercel-forwarded-for':'203.0.113.9'}),response)
    expect(response.code).toBe(403)
    expect(response.body).not.toHaveProperty('summary')
    expect(mocks.createClient).not.toHaveBeenCalled()
  })
  it('denies non-owner accounts before checking any code', async () => {
    mocks.role.mockResolvedValue({data:{role:'member'},error:null})
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(403)
    expect(mocks.verifyOtp).not.toHaveBeenCalled()
  })
  it('denies password sessions older than 10 minutes', async () => {
    mocks.getClaims.mockResolvedValue({
      data:{claims:{sub:'fameverse-owner-id',amr:[{method:'password',timestamp:Math.floor(Date.now()/1000)-900}]}},error:null,
    })
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(403)
    expect(mocks.verifyOtp).not.toHaveBeenCalled()
  })
  it('refuses to verify codes unless code email delivery is activated', async () => {
    vi.stubEnv('OWNER_EMAIL_OTP_ENABLED','')
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(503)
    expect(mocks.verifyOtp).not.toHaveBeenCalled()
  })
  it('rejects invalid numeric code formats before calling Supabase Auth', async () => {
    const response=res()
    await ownerControl(req('summary','not-a-code'),response)
    expect(response.code).toBe(400)
    expect(mocks.verifyOtp).not.toHaveBeenCalled()
  })
  it('rejects valid-looking codes when Supabase says they are wrong', async () => {
    mocks.verifyOtp.mockResolvedValue({data:null,error:{message:'Invalid OTP'}})
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('rejects a code for a different user, even if the code is valid', async () => {
    mocks.verifyOtp.mockResolvedValue({data:{
      user:{id:'other-account',email:'verified@example.test'},session:{access_token:'other-session'},
    },error:null})
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(403)
    expect(mocks.rpc).not.toHaveBeenCalled()
  })
  it('returns only allowlisted summary fields for the same verified owner', async () => {
    const response=res()
    await ownerControl(req(),response)
    expect(response.code).toBe(200)
    expect(response.headers['Cache-Control']).toContain('no-store')
    expect(response.body.authorized).toBe(true)
    expect(response.body.mode).toBe('read-only')
    expect(response.body.summary.reward_reserve_cents).toBe(8400)
    expect(response.body.summary).not.toHaveProperty('private_internal_secret')
    expect(mocks.verifyOtp).toHaveBeenCalledWith({email:'verified@example.test',token:'123456',type:'email'})
    expect(mocks.rpc).toHaveBeenCalledWith('get_owner_finance_control_summary')
  })
  it('exposes the observed IP only after verifying the owner JWT and role', async () => {
    vi.stubEnv('OWNER_ALLOWED_IPS','')
    vi.stubEnv('OWNER_EMAIL_OTP_ENABLED','')
    const response=res()
    await ownerControl(req('status'),response)
    expect(response.code).toBe(200)
    expect(response.body.verifiedAccount).toBe(true)
    expect(response.body.emailOtpReady).toBe(false)
    expect(response.body.ipApproved).toBe(false)
    expect(response.body.observedIP).toBe('203.0.113.8')
    expect(mocks.verifyOtp).not.toHaveBeenCalled()
  })
})
