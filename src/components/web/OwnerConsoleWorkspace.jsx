import { useEffect, useMemo, useState } from 'react'
import WebIcon from './WebIcon.jsx'
import OwnerCaseRecord from './OwnerCaseRecords.jsx'
import '../../styles/web/owner-workspace.css'

// Each menu destination is a real URL, not an anchor that scrolls through Home.
export const OWNER_SECTIONS = [
  ['overview','Overview','⌂','Platform status, people, live rooms and finance'],
  ['users','User Management','♙','Find accounts and prepare safety decisions'],
  ['live','Live Operations','◉','Inspect broadcasts and host activity'],
  ['moderation','Moderation','⚖','Warnings, suspensions, restrictions and appeals'],
  ['gifts','Gifts & Coins','✦','Gift catalog, coin integrity and quality assurance'],
  ['finance','Finance & Payouts','▤','Creator earnings, requests and payout review'],
  ['funding','Owner Funding','♜','Reserve coverage and funding controls'],
  ['reports','Reports & Analytics','▥','Rankings and community performance'],
  ['badges','Badge Requests','◇','Creator verification reviews'],
  ['support','Support & Cases','◌','Help messages, complaints and case review'],
  ['policy','Policy & Compliance','☷','Agreements, notices and enforcement rights'],
  ['system','System Controls','⚙','Release safety, maintenance and notices'],
  ['audit','Audit Logs','☰','Action traceability and accountability'],
]

const ACTIONS = {
  users: [['warn','Warn member'],['suspend','Suspend account'],['ban','Ban account'],['permanent_ban','Permanent ban'],['unban','Remove ban'],['restrict','Restrict features'],['restore_access','Restore access'],['review_activity','Inspect activity']],
  live: [['kick_live','Kick from live'],['end_live','End broadcast'],['mute_live','Mute participant'],['restrict','Restrict live access']],
  moderation: [['warn','Warn'],['suspend','Suspend'],['ban','Ban'],['permanent_ban','Permanent ban'],['unban','Unban'],['restrict','Restrict'],['restore_access','Remove restriction'],['review_fraud','Fraud review']],
  gifts: [['review_fraud','Review suspicious gift activity'],['grant_test_coins','Prepare QA coin grant']],
  finance: [['hold_payout','Hold payout for review'],['release_payout','Review payout release'],['review_fraud','Review chargeback or gifting']],
  funding: [['allocate_reserve','Prepare reserve allocation']],
  badges: [['approve_badge','Approve badge'],['reject_badge','Reject badge']],
  support: [['review_support','Review support case'],['warn','Warn member']],
  policy: [['publish_notice','Prepare policy/update notice'],['restrict','Review policy restriction']],
  system: [['system_maintenance','Prepare maintenance notice'],['staff_permission','Review staff permissions']],
}
const NEEDS_ID = new Set(['warn','suspend','ban','permanent_ban','unban','restrict','restore_access','review_activity','kick_live','end_live','mute_live','review_fraud','grant_test_coins','hold_payout','release_payout','approve_badge','reject_badge','review_support','staff_permission'])

function money(v) {
  return v == null || !Number.isFinite(Number(v)) ? 'Unavailable' :
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(v) / 100)
}
function number(v) {
  return v == null || !Number.isFinite(Number(v)) ? 'Unavailable' : Number(v).toLocaleString('en-US')
}
function Metric({ label, value, description }) {
  return <article className="fv-oc-metric"><span>{label}</span><strong>{value}</strong>{description && <small>{description}</small>}</article>
}
function Notice({ children, kind = 'neutral' }) {
  return <div className={'fv-oc-notice fv-oc-notice-' + kind} role="status">{children}</div>
}
function Row({ item, section, onChoose }) {
  const label = item.display_name || item.username || item.title || item.label ||
    item.gift_id || item.update_type || item.id || item.user_id || 'Record'
  const id = item.id || item.user_id || item.payout_id || ''
  const sub = item.username && item.display_name ? '@' + item.username :
    item.status || item.category || item.update_type || item.verification_status || (id ? 'ID ' + id.slice(0, 10) : 'Fameverse')
  const amount = item.amount_cents != null ? money(item.amount_cents) :
    item.cost_coins != null ? number(item.cost_coins) + ' coins' :
    item.coins_spent != null ? number(item.coins_spent) + ' coins' :
    item.score != null ? 'Rank score: ' + number(item.score) : null
  const actions = ['gifts','policy'].includes(section) ? [] : (ACTIONS[section] || [])
  const targetFor = (operation) => section === 'live'
    ? (operation === 'end_live' ? item.id : item.host_user_id || '')
    : section === 'finance' ? (['hold_payout','release_payout'].includes(operation)
      ? item.payout_id || item.id : item.user_id || item.creator_user_id || '')
    : section === 'badges' ? item.user_id : id
  const targetIds = Object.fromEntries(actions.map(([operation]) => [operation,targetFor(operation)]))
  return <article className="fv-oc-record">
    <div className="fv-oc-record-copy"><strong>{label}</strong><span>{sub}</span>
      {section === 'users' && item.id && <a className="fv-oc-profile-link" href={'/profile/' + encodeURIComponent(item.id)}>Open member profile</a>}
      {item.rank_position != null && <small>Rank #{item.rank_position}</small>}
      {amount && <small>{amount}</small>}
      {item.requested_at && <small>Requested: {new Date(item.requested_at).toLocaleDateString()}</small>}
      {item.started_at && <small>Started: {new Date(item.started_at).toLocaleString()}</small>}
    </div>
    {actions.length > 0 && <div className="fv-oc-row-actions">
      {actions.slice(0, section === 'moderation' ? 4 : section === 'users' ? 3 : 2).map(([key,name]) =>
        <button key={key} type="button" onClick={() => onChoose(key,targetFor(key),targetIds)}>{name}</button>)}
      {actions.length > 2 && <button type="button" onClick={() => onChoose(actions[0][0],targetFor(actions[0][0]),targetIds)}>
        More controls <WebIcon name="arrow" size={15} /></button>}
    </div>}
  </article>
}

function ControlForm({ section, choice, setChoice, onSubmit, busy, result }) {
  const commands = ACTIONS[section]
  if (!commands?.length) return null
  const mustTarget = NEEDS_ID.has(choice.operation)
  return <section className="fv-oc-action-panel" aria-label="Owner action review">
    <div className="fv-oc-panel-heading"><div><span className="fv-oc-eyebrow">REVIEW & VALIDATE</span><h3>Owner controls</h3></div>
      <span className="fv-oc-pill">PREVIEW • NO WRITES</span></div>
    <p>Choose an operation and enter a reason. Validation is connected to the protected owner API, but changes are <strong>not applied</strong> to real members or funds in this preview.</p>
    <form className="fv-oc-form" onSubmit={onSubmit}>
      <label htmlFor="fv-oc-operation">Control
        <select id="fv-oc-operation" value={choice.operation} disabled={busy}
          onChange={(e) => setChoice({ ...choice, operation:e.target.value, targetId:choice.targetIds?.[e.target.value] || '' })}>
          {commands.map(([key,label]) => <option key={key} value={key}>{label}</option>)}
        </select>
      </label>
      {mustTarget && <label htmlFor="fv-oc-target">Target user / room / request ID
        <input id="fv-oc-target" value={choice.targetId} disabled={busy} onChange={(e) => setChoice({ ...choice, targetId: e.target.value.trim() })}
          placeholder="Select an item above, or enter its UUID" required />
      </label>}
      <label htmlFor="fv-oc-reason">Reason and supporting context
        <textarea id="fv-oc-reason" value={choice.reason} disabled={busy} onChange={(e) => setChoice({ ...choice, reason: e.target.value })}
          minLength={12} maxLength={600} required rows={4} placeholder="Explain the evidence, notice and intended review…" />
      </label>
      <button className="fv-oc-primary" type="submit" disabled={busy || choice.reason.trim().length < 12 || (mustTarget && !choice.targetId)}>
        {busy ? 'Validating…' : 'Validate in preview'}
      </button>
    </form>
    {result && <Notice kind={result.error ? 'error' : 'warning'}>
      {result.error || result.message}
      {!result.error && <p><strong>No changes applied. No persistent audit event recorded.</strong></p>}
    </Notice>}
  </section>
}

function sectionFromLocation() {
  const key = window.location.pathname.split('/')[2] || 'overview'
  return OWNER_SECTIONS.some(([name]) => name === key) ? key : 'overview'
}

function filtersFromLocation() {
  const params = new URLSearchParams(window.location.search)
  return {caseId:params.get('caseId') || '',targetId:params.get('targetId') || ''}
}

export default function OwnerConsoleWorkspace({ token, overview, onLock }) {
  const [section, setSection] = useState(sectionFromLocation)
  const info = OWNER_SECTIONS.find(([key]) => key === section)
  const [searchDraft, setSearchDraft] = useState('')
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(0)
  const [filters, setFilters] = useState(filtersFromLocation)
  const [version, setVersion] = useState(0)
  const [kind, setKind] = useState('creators')
  const [windowName, setWindowName] = useState('daily')
  const [data, setData] = useState({ key:null, state:'loading', value:null, error:'' })
  // Never reuse owner records after navigation: an IP or role can change
  // between requests, so each section requires a fresh protected server read.
  const options = ACTIONS[section] || []
  const [choice, setChoice] = useState({ operation:options[0]?.[0] || '', targetId:'', reason:'' })
  const [actionBusy, setActionBusy] = useState(false)
  const [actionOpen, setActionOpen] = useState(false)
  const [actionResult, setActionResult] = useState(null)
  const [previewHistory, setPreviewHistory] = useState([])
  const currentLabel = useMemo(() => info?.[1] || 'Overview',[info])
  const requestKey = JSON.stringify([section,page,query,kind,windowName,version,filters.caseId,filters.targetId])

  // Section transitions stay inside one signed-in workspace. Browser Back/Forward
  // updates the selected section without refreshing Supabase auth or remounting.
  useEffect(() => {
    const syncRoute = () => {
      setSection(sectionFromLocation())
      setFilters(filtersFromLocation())
      setPage(0)
      setSearchDraft('')
      setQuery('')
      setActionOpen(false)
      setActionResult(null)
    }
    window.addEventListener('popstate',syncRoute)
    return () => window.removeEventListener('popstate',syncRoute)
  }, [])

  const navigate = (event, key) => {
    if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    event.preventDefault()
    const destination = event.currentTarget.getAttribute('href') || (key === 'overview' ? '/owner' : '/owner/' + key)
    if (window.location.pathname + window.location.search !== destination) window.history.pushState({},'',destination)
    setSection(key)
    setFilters(filtersFromLocation())
    setPage(0)
    setSearchDraft('')
    setQuery('')
    setActionOpen(false)
    setActionResult(null)
    window.scrollTo({top:0,behavior:'instant'})
  }

  // Search executes after the owner stops typing. Pressing Search below
  // can commit it immediately, but entering each character never calls the API.
  useEffect(() => {
    const timer = window.setTimeout(() => {
      setPage(0)
      setQuery(searchDraft.trim())
    }, 350)
    return () => window.clearTimeout(timer)
  }, [searchDraft])

  // A revoked owner session or changed IP must invalidate all private UI state.
  // The parent removes this workspace and requires a fresh server access check.
  const lockWorkspace = () => {
    setData({key:null,state:'loading',value:null,error:''})
    setActionResult(null)
    setPreviewHistory([])
    setActionOpen(false)
    onLock()
  }

  useEffect(() => {
    // An 80ms coalescing window avoids StrictMode's dev-only setup/cleanup
    // cycle firing two real network requests. Abort cancels stale requests.
    const controller = new AbortController()
    let active = true
    setData({key:requestKey,state:'loading',value:null,error:''})
    const timer = window.setTimeout(() => {
      fetch('/api/owner/console', {
        method:'POST',credentials:'same-origin',cache:'no-store',signal:controller.signal,
        headers:{'Content-Type':'application/json',Authorization:'Bearer ' + token},
        body:JSON.stringify({action:'read',section,page,query,kind,window:windowName,...filters}),
      }).then(async (response) => {
        if (response.status === 401 || response.status === 403) {
          if (active) lockWorkspace()
          return
        }
        if (!String(response.headers.get('content-type') || '').includes('application/json')) throw new Error('Secure preview session unavailable.')
        const body = await response.json()
        if (!response.ok || !body?.authorized) throw new Error(body?.error || 'Owner records unavailable.')
        if (active) {
          setData({key:requestKey,state:'ready',value:body,error:''})
        }
      }).catch((error) => {
        if (active && error.name !== 'AbortError') setData({key:requestKey,state:'error',value:null,error:error.message})
      })
    }, 80)
    return () => {active=false;window.clearTimeout(timer);controller.abort()}
  }, [token,section,page,query,version,kind,windowName,requestKey])

  const selectAction = (operation, targetId = '', targetIds = {}) => {
    setChoice({ operation, targetId:targetId || '', targetIds, reason:'' })
    setActionResult(null)
    setActionOpen(true)
  }
  const submitAction = async (event) => {
    event.preventDefault()
    setActionBusy(true)
    setActionResult(null)
    try {
      const response = await fetch('/api/owner/console',{
        method:'POST',credentials:'same-origin',cache:'no-store',
        headers:{'Content-Type':'application/json',Authorization:'Bearer ' + token},
        body:JSON.stringify({action:'preview_action',...choice}),
      })
      if (response.status === 401 || response.status === 403) {
        lockWorkspace()
        return
      }
      const body = await response.json()
      if (!response.ok || !body.authorized) { setActionResult({error:body.error || 'Validation failed'});return }
      setActionResult(body)
      setPreviewHistory(h => [{id:body.id,operation:body.operation,reason:body.reason,applied:false},...h].slice(0,12))
    } catch {setActionResult({error:'Could not reach protected validation service.'})}
    finally {setActionBusy(false)}
  }

  const renderContent = () => {
    const shown = data.key === requestKey ? data : {state:'loading',value:null,error:''}
    if (shown.state === 'loading') return <div className="fv-oc-loading" role="status">Loading verified {currentLabel.toLowerCase()} data…</div>
    if (shown.state === 'error') return <Notice kind="error">{shown.error} <button type="button" onClick={() => setVersion(n => n+1)}>Retry</button></Notice>
    const v = shown.value || {}
    if (v.availability) return <Notice kind="warning">{v.message || 'This source needs an audited backend before live access is allowed.'}</Notice>
    if (section === 'overview') {
      const o=v.overview || overview || {}
      return <>
        <div className="fv-oc-metrics">
          <Metric label="Public profiles" value={number(v.users)} />
          <Metric label="Live right now" value={number(v.live)} />
          <Metric label="Reward reserve" value={money(o.reward_reserve_cents)} />
          <Metric label="Unpaid creator earnings" value={money(o.creator_earnings_unpaid_cents)} />
          <Metric label="Outstanding cash-backed coins" value={number(o.cash_backed_coins_outstanding)} />
          <Metric label="Platform share earned" value={money(o.platform_share_earned_cents)} />
          <Metric label="Payouts in review" value={money(o.creator_payouts_in_review_cents)} />
          <Metric label="Lifetime reserve allocated" value={money(o.reward_reserve_lifetime_cents)} />
        </div>
        {v.warnings?.length > 0 && <Notice kind="warning">{v.warnings.join(' · ')}</Notice>}
        <div className="fv-oc-quick"><h3>Operate your platform</h3><div>
          {['users','live','moderation','finance','support','policy'].map(key => {
            const item=OWNER_SECTIONS.find(s=>s[0]===key)
            return <a key={key} href={'/owner/'+key} onClick={(event)=>navigate(event,key)}><span>{item[2]}</span>{item[1]} <WebIcon name="arrow" size={16}/></a>
          })}
        </div></div>
      </>
    }
    if (section === 'funding') {
      const v2=v.summary || {}
      return <><div className="fv-oc-metrics">
        <Metric label="Available reserve" value={money(v2.reserve_gross_cents)} />
        <Metric label="Lifetime allocations" value={money(v2.lifetime_allocated_gross_cents)} />
        <Metric label="Coins per USD" value={number(v2.coins_per_usd)} />
        <Metric label="Creator share" value={v2.creator_share_bps == null ? 'Unavailable' : (v2.creator_share_bps/100) + '%'} />
      </div><Notice>Funding and payouts are separate controls. No allocation is performed in this production-connected preview.</Notice></>
    }
    const items=Array.isArray(v.items) ? v.items : []
    return <>
      {section === 'finance' && <Notice kind="warning">Creator payouts remain paused. This panel is for viewing pending requests and validating review decisions; no payout can be issued or released here.</Notice>}
      {section === 'badges' && <Notice kind="warning">This is the existing creator verification queue. Imported badge requests and screenshot evidence require a separate case intake before approval is possible.</Notice>}
      {section === 'moderation' && <Notice>High-impact actions require case evidence, human review, notice and an appeal route. A refund or chargeback alone is not proof of fraud.</Notice>}
      {section === 'finance' && <div className="fv-oc-metrics">
        <Metric label="Unpaid creator earnings" value={money(v.summary?.creator_earnings_unpaid_cents)} />
        <Metric label="Payouts pending review" value={money(v.summary?.creator_payouts_in_review_cents)} />
        <Metric label="Creator share earned" value={money(v.summary?.creator_share_earned_cents)} />
        <Metric label="Platform share earned" value={money(v.summary?.platform_share_earned_cents)} />
      </div>}
      {v.warnings?.length > 0 && <Notice kind="warning">{v.warnings.join(' · ')}</Notice>}
      {section === 'policy' && <Notice kind="warning">Active release notices are shown below. Policy acceptance history and appeal enforcement need a separate audited backend; no acceptance counts are invented.</Notice>}
      {section === 'gifts' && <Notice>Gift prices and activation are read from the existing catalog. Coin grants, cash-backed gifts and payout changes are disabled in preview.</Notice>}
      {section === 'system' && <Notice>Live release state is read-only. No CodeMagic, TestFlight, Supabase, Stripe or Vercel settings can be changed from this preview.</Notice>}
      {section === 'support' && <Notice>Protected support intake and linked cases are read-only. Case lifecycle changes require a separately approved backend.</Notice>}
      {section === 'audit' && <Notice>These are durable records returned by protected audit storage. Preview validations do not create audit events.</Notice>}
      {items.length === 0 ? <Notice>No records are available to your current authorized view. This is not proof that there are no records elsewhere.</Notice> :
        <div className="fv-oc-records">{items.map((item,i)=>['support','audit'].includes(section) ?
          <OwnerCaseRecord key={item.id} item={item} section={section} onNavigate={navigate} onChoose={selectAction}/> :
          <Row key={item.id || item.user_id || item.payout_id || i} item={item} section={section} onChoose={selectAction}/>)}</div>}
      {v.total != null && <div className="fv-oc-pagination">
        <span>Page {page+1} · {number(v.total)} total records</span>
        <button type="button" disabled={page===0} onClick={()=>setPage(n=>Math.max(0,n-1))}>Previous</button>
        <button type="button" disabled={(page+1)*25>=v.total} onClick={()=>setPage(n=>n+1)}>Next</button>
      </div>}
      {section === 'reports' && items.length > 0 && <Notice>This is a rolling 24-hour or 7-day report, not the planned UTC calendar-reset leaderboard. All-time rankings still need backend integration.</Notice>}
    </>
  }

  return <div className="fv-oc-shell">
    <aside className="fv-oc-sidebar" aria-label="Owner Command Center sections">
      <a href="/" className="fv-oc-return"><WebIcon name="home" size={17}/> Return to Fameverse Home</a>
      <span className="fv-oc-sidebar-label">OWNER OPERATIONS</span>
      <nav>{OWNER_SECTIONS.map(([key,label,icon])=><a key={key} href={key==='overview'?'/owner':'/owner/'+key} onClick={(event)=>navigate(event,key)}
        aria-current={section===key?'page':undefined} className={section===key?'fv-oc-nav-active':''}><span aria-hidden="true">{icon}</span>{label}</a>)}</nav>
      <div className="fv-oc-sidebar-foot"><strong>Owner + approved IP</strong><span>All actions require server checks.</span></div>
    </aside>
    <div className="fv-oc-main">
      <div className="fv-oc-top">
        <div><span className="fv-oc-eyebrow">OWNER COMMAND CENTER / {info[1].toUpperCase()}</span>
          <h2>{info[1]}</h2><p>{info[3]}</p></div>
        <div className="fv-oc-top-actions"><a href="/">Home</a>
          <button type="button" onClick={()=>setVersion(n=>n+1)}><WebIcon name="refresh" size={16}/>Refresh</button>
          <button type="button" onClick={onLock}>Lock</button></div>
      </div>
      {section !== 'overview' && <Notice kind="warning">Controlled preview. Data is read from existing authorized sources; all enforcement and money-changing operations are validated only, never applied to live accounts.</Notice>}
      {(section==='users'||section==='moderation')&&<form className="fv-oc-search" onSubmit={(e)=>{e.preventDefault();setPage(0);setQuery(searchDraft.trim())}}>
        <label htmlFor="fv-oc-user-search">Search member usernames</label>
        <input id="fv-oc-user-search" value={searchDraft} onChange={(e)=>setSearchDraft(e.target.value)} placeholder="Username..." />
        <button type="submit">Search</button>
      </form>}
      {section==='reports'&&<div className="fv-oc-filters">
        <label>Ranking type<select value={kind} onChange={(e)=>setKind(e.target.value)}><option value="creators">Creators</option><option value="supporters">Supporters</option></select></label>
        <label>Time window<select value={windowName} onChange={(e)=>setWindowName(e.target.value)}><option value="daily">Past 24 hours</option><option value="weekly">Past 7 days</option><option value="all_time">All-time (pending)</option></select></label>
      </div>}
      <div className="fv-oc-section-content">{renderContent()}</div>
      {(filters.caseId || filters.targetId) && <Notice>Filtered by {filters.caseId ? 'case ' + filters.caseId : 'target ' + filters.targetId}. <a href={'/owner/'+section} onClick={event=>navigate(event,section)}>Clear filter</a></Notice>}
      {options.length>0&&!actionOpen&&<div className="fv-oc-toolbar">
        <button className="fv-oc-primary" type="button" onClick={()=>selectAction(options[0][0])}>
          Review available {info[1].toLowerCase()} controls
        </button>
        <span>Preview validation only — no account or financial changes</span>
      </div>}
      {actionOpen && <div className="fv-oc-modal-backdrop" onMouseDown={(event) => {if(event.target===event.currentTarget&&!actionBusy) setActionOpen(false)}}>
        <div className="fv-oc-modal" role="dialog" aria-modal="true" aria-label="Review owner control"
          onKeyDown={(event) => {if(event.key==='Escape'&&!actionBusy) setActionOpen(false)}}>
          <div className="fv-oc-modal-close"><button type="button" disabled={actionBusy} onClick={() => setActionOpen(false)}>Close</button></div>
          <ControlForm section={section} choice={choice} setChoice={value=>{setChoice(value);setActionResult(null)}}
            onSubmit={submitAction} busy={actionBusy} result={actionResult}/>
        </div>
      </div>}
      {section==='audit'&& <section className="fv-oc-action-panel"><h3>Current-page validation history</h3>
        <p>These are temporary validation responses, not a permanent audit log. No database history is created in preview.</p>
        {previewHistory.length?previewHistory.map(x=><div key={x.id} className="fv-oc-history">{x.operation}: not applied</div>):
          <Notice>No persistent audit records are accessible yet. An audited backend is required before enforcement can be activated.</Notice>}</section>}
    </div>
  </div>
}
