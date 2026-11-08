import { useEffect, useMemo, useState } from 'react'
import { useCreatorDiscovery } from '../../hooks/useCreatorDiscovery.js'
import { useLiveDiscovery } from '../../hooks/useLiveDiscovery.js'
import WebCommunityCard from './WebCommunityCard.jsx'
import WebCommunityDialog from './WebCommunityDialog.jsx'
import WebIcon from './WebIcon.jsx'

function AuthenticatedCommunity({ userId, query }) {
  const creators = useCreatorDiscovery({ userId })
  const live = useLiveDiscovery({ userId })
  const [selected, setSelected] = useState(null)
  const [filter, setFilter] = useState('creators')
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 10000)
    return () => window.clearInterval(timer)
  }, [])
  const search = query.trim().toLowerCase()
  const creatorResults = useMemo(() => creators.creators.filter((creator) => `${creator.displayName} ${creator.username || ''} ${creator.bio || ''}`.toLowerCase().includes(search)), [creators.creators, search])
  const roomResults = useMemo(() => live.rooms.filter((room) => {
    const heartbeat = Date.parse(room.heartbeat_at)
    const recent = Number.isFinite(heartbeat) && now - heartbeat < 45000
    const visible = live.state === 'degraded' || (room.status === 'live' && recent)
    return visible && `${room.title || ''} ${room.host?.displayName || ''} ${room.host?.username || ''}`.toLowerCase().includes(search)
  }), [live.rooms, live.state, now, search])
  const current = filter === 'live' ? live : creators
  const results = filter === 'live' ? roomResults : creatorResults
  const refresh = () => { void creators.refresh(); void live.refresh() }

  return <>
    <div className="fv-community-toolbar"><div className="fv-community-tabs" role="group" aria-label="Community view"><button type="button" aria-pressed={filter === 'creators'} onClick={() => setFilter('creators')}>Creators</button><button type="button" aria-pressed={filter === 'live'} onClick={() => setFilter('live')}>Live in the app</button></div><button className="fv-community-refresh" type="button" onClick={refresh}><WebIcon name="refresh" size={16} />Refresh</button></div>
    {current.state === 'degraded' && <p className="fv-community-warning" role="status">Connection limited. {results.length ? 'Showing previously loaded results; live status may have changed.' : 'We could not load this community view. Refresh to try again.'}</p>}
    {(current.state === 'idle' || current.state === 'loading') && <div className="fv-community-loading" role="status">Connecting to your creator community…</div>}
    {results.length > 0 && <div className="fv-community-grid">{results.slice(0, 8).map((item) => <WebCommunityCard key={item.id} item={item} live={filter === 'live'} confirmed={current.state === 'ready'} onSelect={() => filter === 'live' ? setSelected({ item, live: true, confirmed: current.state === 'ready' }) : window.location.assign(`/?profile=${encodeURIComponent(item.id)}`)} />)}</div>}
    {current.state === 'ready' && results.length === 0 && <div className="fv-community-empty"><WebIcon name={filter === 'live' ? 'home' : 'people'} size={30} /><h3>{search ? 'No matches for your search' : filter === 'live' ? 'No active live rooms right now' : 'Your creator community is growing'}</h3><p>{search ? 'Try a different creator name or live title.' : filter === 'live' ? 'Real live rooms appear here when creators go live in Fameverse.' : 'Creator profiles will appear as the community grows. Check back soon.'}</p></div>}
    {filter === 'live' && <p className="fv-community-playback-note">Live playback remains in the existing Fameverse app. This website preview does not change media, gifts, or wallet behavior.</p>}
    <WebCommunityDialog selected={selected} onClose={() => setSelected(null)} />
  </>
}

export default function WebCommunity({ userId, query, onSignIn }) {
  return (
    <section className="fv-community-section" id="discover-creators">
      <div className="fv-community-heading"><div><span className="fv-web-eyebrow">FIND YOUR PEOPLE</span><h2>Your next favorite creator.</h2><p>Real people. Real community. All on Fameverse.</p></div><span className="fv-community-label">CREATOR COMMUNITY</span></div>
      {userId ? <AuthenticatedCommunity key={userId} userId={userId} query={query} /> : <div className="fv-community-guest"><div className="fv-community-guest-symbol" aria-hidden="true"><WebIcon name="people" size={36} /></div><div><span className="fv-web-eyebrow">MAKE IT YOURS</span><h3>Come for the creators.<br />Stay for the connection.</h3><p>Sign in with your Fameverse account to discover creator profiles and see who's live. Your account stays the same across web and app.</p><button className="fv-platform-signin" type="button" onClick={onSignIn}>Sign in to explore<WebIcon name="arrow" size={17} /></button></div><div className="fv-community-guest-features"><span>Discover your community</span><span>Keep your Fameverse identity</span><span>Support your favorite creators</span></div></div>}
    </section>
  )
}
