import { describe, expect, it } from 'vitest'
import ownerHandler from '../../api/owner/control.js'

function res() { return {headers:{},statusCode:null,body:null,
  setHeader(k,v){this.headers[k]=v;return this},
  status(v){this.statusCode=v;return this},
  json(v){this.body=v;return this},
}}
describe('Owner API refuses unauthenticated, unapproved, unconfigured access',()=>{
  it('has no public owner data when the IP is not configured',async()=>{
    const existing=process.env.OWNER_ALLOWED_IPS
    try {
      delete process.env.OWNER_ALLOWED_IPS
      const r=res()
      await ownerHandler({method:'GET',headers:{}},r)
      expect(r.statusCode).toBe(200)
      expect(r.body).toEqual({configured:false})
      expect(r.headers['Cache-Control']).toContain('no-store')
    } finally {
      if(existing===undefined) delete process.env.OWNER_ALLOWED_IPS
      else process.env.OWNER_ALLOWED_IPS=existing
    }
  })
  it('exposes no private owner data when an IP is configured',async()=>{
    const existing=process.env.OWNER_ALLOWED_IPS
    try {
      process.env.OWNER_ALLOWED_IPS='203.0.113.8'
      const r=res()
      await ownerHandler({method:'GET',headers:{}},r)
      expect(r.statusCode).toBe(200)
      expect(r.body).toEqual({configured:true})
      expect(r.body).not.toHaveProperty('summary')
      expect(r.body).not.toHaveProperty('allowedIPs')
      expect(r.headers['Cache-Control']).toContain('no-store')
    } finally {
      if(existing===undefined) delete process.env.OWNER_ALLOWED_IPS
      else process.env.OWNER_ALLOWED_IPS=existing
    }
  })
  it('rejects unsupported methods',async()=>{
    const r=res()
    await ownerHandler({method:'PUT',headers:{}},r)
    expect(r.statusCode).toBe(405)
  })
  it('denies summary from any IP if no approved IP was configured',async()=>{
    const existing=process.env.OWNER_ALLOWED_IPS
    try{
      delete process.env.OWNER_ALLOWED_IPS
      const r=res()
      await ownerHandler({method:'POST',
        headers:{host:'example.test',origin:'https://example.test','x-vercel-forwarded-for':'203.0.113.3',authorization:'Bearer fake.valid.jwt'},
        body:{action:'summary'}},r)
      expect(r.statusCode).toBe(403)
      expect(r.body.summary).toBeUndefined()
    }finally{
      if(existing===undefined) delete process.env.OWNER_ALLOWED_IPS
      else process.env.OWNER_ALLOWED_IPS=existing
    }
  })
})
