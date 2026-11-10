import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
const read=p=>readFileSync(new URL('../../'+p,import.meta.url),'utf8')
const header=read('src/components/web/WebHeader.jsx')
const store=read('src/components/web/WebStore.jsx')
const page=read('src/components/web/OwnerConsoleWorkspace.jsx')
const routes=JSON.parse(read('vercel.json'))
describe('Owner Command Center pages and controls',()=>{
  it('returns to the owner center from Home and the account menu',()=>{
    expect(header).toContain('Owner Command Center')
    const topNavigation = header.split('<nav className="fv-platform-topnav"')[1]?.split('</nav>')[0]
    expect(topNavigation).toContain('Home')
    expect(topNavigation).toContain('Discover')
    expect(topNavigation).not.toContain('href="/owner"')
    expect(header).not.toContain('fv-owner-nav-link')
    // The owner entry remains private to the signed-in account menu,
    // and backend owner + IP verification continues to protect /owner.
    expect(header).toContain('Owner Command Center')
    expect(header).toContain("account.profile?.account_role === 'owner'")
    expect(page).toContain('Return to Fameverse Home')
  })
  it('has original planned destinations as dedicated pages',()=>{
    for(const label of ['Overview','User Management','Live Operations','Moderation',
      'Gifts & Coins','Finance & Payouts','Owner Funding','Reports & Analytics',
      'Policy & Compliance','System Controls','Audit Logs','Badge Requests','Support & Cases']){
      expect(page).toContain(label)
    }
    expect(routes.rewrites).toContainEqual({source:'/owner/:section',destination:'/index.html'})
    expect(store).toContain("window.location.pathname.startsWith('/owner/')")
  })
  it('provides direct moderation, live and finance buttons wired to protected validation',()=>{
    for(const label of ['Warn member','Suspend account','Permanent ban','Kick from live',
      'End broadcast','Hold payout for review','Prepare reserve allocation','Approve badge','Reject badge']){
      expect(page).toContain(label)
    }
    expect(page).toContain('Validate in preview')
    expect(page).toContain("window.history.pushState")
    expect(page).toContain("window.addEventListener('popstate'")
    expect(page).toContain("350)")
    // No private caching: each navigation rechecks server-side IP and owner role.
    expect(page).not.toContain('cachedReads.current.get(requestKey)')
    expect(page).not.toContain('cachedReads.current.set(requestKey')
    expect(page).toContain('response.status === 401 || response.status === 403')
    expect(page).toContain('lockWorkspace()')
    expect(page).toContain('setPreviewHistory([])')
    expect(page).toContain('onLock()')
    expect(page).toContain("window.clearTimeout(timer)")
    expect(page).toContain("Review available {info[1].toLowerCase()} controls")
    expect(page).not.toContain('options.length>0&&!actionOpen&&<div id="fv-owner-controls"><ControlForm')

    expect(page).toContain('role="dialog"')
    expect(page).not.toContain('scrollIntoView')
    expect(page).toContain('No changes applied. No persistent audit event recorded.')
    expect(page).toContain("fetch('/api/owner/console'")
    expect(page).toContain("v.summary?.creator_earnings_unpaid_cents")
    expect(page).toContain("v.summary?.creator_payouts_in_review_cents")
    const gate=read('src/components/web/WebOwnerCommandCenter.jsx')
    expect(gate).toContain("body: JSON.stringify({ action: 'access' })")
    expect(gate).toContain("current.state === 'ready' ?")
  })
})
