import { useEffect, useRef, useState } from 'react'
import { supabase } from '../../services/supabase.js'
import WebCommunityCard from './WebCommunityCard.jsx'
import WebIcon from './WebIcon.jsx'

const PAGE_SIZE = 36
const PROFILE_FIELDS = 'id,username,display_name,bio,avatar_url,created_at'

// Query public profile fields only. Never request private auth emails or credentials.
function directoryQuery(keyword, start) {
  let request = supabase.from('profiles')
    .select(PROFILE_FIELDS, { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(start, start + PAGE_SIZE - 1)

  const cleaned = keyword.trim().replace(/[(),.%*\\]/g, ' ').replace(/\s+/g, ' ').slice(0, 60).trim()
  if (cleaned) request = request.or(`display_name.ilike.%${cleaned}%,username.ilike.%${cleaned}%,bio.ilike.%${cleaned}%`)
  return request
}

export default function WebCommunity({ userId, query = '', onSignIn }) {
  const [members, setMembers] = useState([])
  const [total, setTotal] = useState(null)
  const [loading, setLoading] = useState(true)
  const [moreBusy, setMoreBusy] = useState(false)
  const [error, setError] = useState('')
  const [hasMore, setHasMore] = useState(false)
  const generation = useRef(0)

  useEffect(() => {
    const current = ++generation.current
    setLoading(true)
    setError('')
    setMembers([])
    setTotal(null)
    setHasMore(false)
    directoryQuery(query, 0).then(({ data, error: requestError, count }) => {
      if (generation.current !== current) return
      if (requestError) { setError('Unable to load members. Try refreshing Discover.'); return }
      const rows = data || []
      setMembers(rows)
      setTotal(count)
      setHasMore(count === null ? rows.length === PAGE_SIZE : rows.length < count)
    }).catch(() => {
      if (generation.current === current) setError('Unable to connect to the member directory.')
    }).finally(() => {
      if (generation.current === current) setLoading(false)
    })
    return () => { generation.current += 1 }
  }, [query])

  const loadMore = async () => {
    if (loading || moreBusy || !hasMore) return
    const current = generation.current
    setMoreBusy(true)
    setError('')
    try {
      const { data, error: requestError, count } = await directoryQuery(query, members.length)
      if (generation.current !== current) return
      if (requestError) { setError('Unable to load more members. Please try again.'); return }
      const rows = data || []
      setMembers((previous) => {
        const seen = new Set(previous.map((member) => member.id))
        return [...previous, ...rows.filter((member) => !seen.has(member.id))]
      })
      setTotal(count)
      setHasMore(count === null ? rows.length === PAGE_SIZE : members.length + rows.length < count)
    } catch {
      if (generation.current === current) setError('Unable to load more members. Please try again.')
    } finally {
      if (generation.current === current) setMoreBusy(false)
    }
  }

  return <section className="fv-community-section fv-members-directory" id="discover-creators">
    <div className="fv-community-heading">
      <div><span className="fv-web-eyebrow">FAMEVERSE COMMUNITY</span><h1>Discover members</h1><p>Explore public profiles from the Fameverse app, not a limited creator shortlist.</p></div>
      <span className="fv-community-label">{total === null ? 'MEMBER DIRECTORY' : `${total.toLocaleString('en-US')} MEMBERS`}</span>
    </div>
    {!userId && <div className="fv-directory-guest"><span>Profiles are public. Sign in to follow members.</span><button type="button" onClick={onSignIn}>Sign in</button></div>}
    {loading && <div className="fv-community-loading" role="status">Loading Fameverse members…</div>}
    {error && <p className="fv-community-warning" role="alert">{error}</p>}
    {!loading && members.length > 0 && <div className="fv-community-grid">
      {members.map((member) => <WebCommunityCard key={member.id} item={{
        id: member.id,
        displayName: member.display_name || member.username || 'Fameverse member',
        username: member.username,
        bio: member.bio || '',
        avatarUrl: member.avatar_url || null,
      }} live={false} confirmed onSelect={() => window.location.assign(`/profile/${encodeURIComponent(member.id)}`)} />)}
    </div>}
    {!loading && !error && members.length === 0 && <div className="fv-community-empty">
      <WebIcon name="people" size={30} /><h2>No members found</h2><p>{query ? 'Try a different name or username.' : 'No public member profiles are available.'}</p>
    </div>}
    {hasMore && !loading && <div className="fv-directory-more"><button type="button" onClick={loadMore} disabled={moreBusy}>{moreBusy ? 'Loading…' : 'Load more members'}</button></div>}
    {!loading && members.length > 0 && <p className="fv-directory-count">Showing {members.length.toLocaleString('en-US')}{total === null ? '' : ` of ${total.toLocaleString('en-US')}`} public profiles</p>}
  </section>
}
