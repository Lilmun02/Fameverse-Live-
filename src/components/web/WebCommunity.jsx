import { useMemo, useState } from 'react'
import { useCreatorDiscovery } from '../../hooks/useCreatorDiscovery.js'
import WebCommunityCard from './WebCommunityCard.jsx'
import WebCommunityDialog from './WebCommunityDialog.jsx'
import WebIcon from './WebIcon.jsx'

function AuthenticatedCommunity({ userId, query }) {
  const creators = useCreatorDiscovery({ userId })
  const [selected, setSelected] = useState(null)
  const search = query.trim().toLowerCase()
  const creatorResults = useMemo(() => creators.creators.filter((creator) => `${creator.displayName} ${creator.username || ''} ${creator.bio || ''}`.toLowerCase().includes(search)), [creators.creators, search])
  const refresh = () => { void creators.refresh() }

  return <>
    <div className="fv-community-toolbar"><p>Discover Fameverse creators</p><button className="fv-community-refresh" type="button" onClick={refresh}><WebIcon name="refresh" size={16} />Refresh</button></div>
    {creators.state === 'degraded' && <p className="fv-community-warning" role="status">Connection limited. {creatorResults.length ? 'Showing previously loaded creators.' : 'We could not load creators. Refresh to try again.'}</p>}
    {(creators.state === 'idle' || creators.state === 'loading') && <div className="fv-community-loading" role="status">Connecting to your creator community…</div>}
    {creatorResults.length > 0 && <div className="fv-community-grid">{creatorResults.slice(0, 8).map((item) => <WebCommunityCard key={item.id} item={item} live={false} confirmed={creators.state === 'ready'} onSelect={() => setSelected({ item, live: false, confirmed: creators.state === 'ready' })} />)}</div>}
    {creators.state === 'ready' && creatorResults.length === 0 && <div className="fv-community-empty"><WebIcon name="people" size={30} /><h3>{search ? 'No matches for your search' : 'Your creator community is growing'}</h3><p>{search ? 'Try a different creator name.' : 'Creator profiles will appear as the community grows. Check back soon.'}</p></div>}
    <WebCommunityDialog selected={selected} onClose={() => setSelected(null)} />
  </>
}

export default function WebCommunity({ userId, query, onSignIn }) {
  return (
    <section className="fv-community-section" id="discover-creators">
      <div className="fv-community-heading"><div><span className="fv-web-eyebrow">FIND YOUR PEOPLE</span><h2>Your next favorite creator.</h2><p>Real people. Real community. All on Fameverse.</p></div><span className="fv-community-label">CREATOR COMMUNITY</span></div>
      {userId ? <AuthenticatedCommunity key={userId} userId={userId} query={query} /> : <div className="fv-community-guest"><div className="fv-community-guest-symbol" aria-hidden="true"><WebIcon name="people" size={36} /></div><div><span className="fv-web-eyebrow">MAKE IT YOURS</span><h3>Come for the creators.<br />Stay for the connection.</h3><p>Sign in with your Fameverse account to discover creator profiles and explore creator profiles. Your account stays the same across web and app.</p><button className="fv-platform-signin" type="button" onClick={onSignIn}>Sign in to explore<WebIcon name="arrow" size={17} /></button></div><div className="fv-community-guest-features"><span>Discover your community</span><span>Keep your Fameverse identity</span><span>Support your favorite creators</span></div></div>}
    </section>
  )
}
