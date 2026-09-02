import { useMemo, useState } from 'react'

const FILTERS = ['For You', 'Following', 'Friends']
const compactNumber = new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 })

function formatStat(value) {
  const number = Number(value)
  return compactNumber.format(Number.isFinite(number) && number > 0 ? number : 0)
}

function creatorInitial(creator) {
  return String(creator?.displayName || creator?.username || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function creatorHandle(creator) {
  return creator?.username ? `@${creator.username}` : '@fameverse'
}

function matchesQuery(query, values) {
  if (!query) return true
  return values.filter(Boolean).join(' ').toLowerCase().includes(query)
}

export default function DiscoverScreen({
  setTab,
  liveDiscovery,
  creatorDiscovery,
  followNetwork,
  currentProfile,
  onOpenLiveRoom,
}) {
  const [filter, setFilter] = useState('For You')
  const [query, setQuery] = useState('')
  const normalizedQuery = query.trim().toLowerCase()
  const rooms = liveDiscovery?.rooms || []
  const creators = creatorDiscovery?.creators || []

  const followingIds = useMemo(
    () => new Set((followNetwork?.following || []).map((profile) => profile.id)),
    [followNetwork?.following],
  )
  const followerIds = useMemo(
    () => new Set((followNetwork?.followers || []).map((profile) => profile.id)),
    [followNetwork?.followers],
  )
  const friendIds = useMemo(
    () => new Set([...followingIds].filter((id) => followerIds.has(id))),
    [followerIds, followingIds],
  )

  const filterAllows = (userId) => {
    if (filter === 'Following') return followingIds.has(userId)
    if (filter === 'Friends') return friendIds.has(userId)
    return true
  }

  const visibleRooms = useMemo(() => rooms.filter((room) => {
    if (!filterAllows(room.host_user_id)) return false
    return matchesQuery(normalizedQuery, [
      room.title,
      room.host?.displayName,
      room.host?.username,
    ])
  }), [filter, friendIds, followingIds, normalizedQuery, rooms])

  const visibleCreators = useMemo(() => creators.filter((creator) => {
    if (!filterAllows(creator.id)) return false
    return matchesQuery(normalizedQuery, [
      creator.displayName,
      creator.username,
      creator.bio,
    ])
  }), [creators, filter, friendIds, followingIds, normalizedQuery])

  const openLiveRoom = (room) => {
    window.FameverseGiftEngine?.startAudioSession?.()
    onOpenLiveRoom?.(room)
  }

  const profileInitial = creatorInitial({
    displayName: currentProfile?.display_name,
    username: currentProfile?.username,
  })

  return (
    <section className="fv-discover" aria-labelledby="discover-title">
      <header className="fv-discover-topbar">
        <div className="fv-discover-brand">
          <span>FAMEVERSE</span>
          <h1 id="discover-title">Discover</h1>
        </div>
        <button type="button" className="fv-discover-profile" onClick={() => setTab('profile')} aria-label="Open profile">
          {currentProfile?.avatar_url ? <img src={currentProfile.avatar_url} alt="" /> : <span>{profileInitial}</span>}
        </button>
      </header>

      <label className="fv-discover-search">
        <span aria-hidden="true">⌕</span>
        <input
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search creators or live titles"
          aria-label="Search creators or live titles"
        />
        {query && (
          <button type="button" onClick={() => setQuery('')} aria-label="Clear search">×</button>
        )}
      </label>

      <div className="fv-discover-filters" role="tablist" aria-label="Discovery filters">
        {FILTERS.map((label) => (
          <button
            key={label}
            type="button"
            role="tab"
            aria-selected={filter === label}
            className={filter === label ? 'active' : ''}
            onClick={() => setFilter(label)}
          >
            {label}
          </button>
        ))}
      </div>

      <section className="fv-discover-section" aria-labelledby="live-now-title">
        <div className="fv-discover-section-heading">
          <div>
            <span>LIVE NOW</span>
            <h2 id="live-now-title">Streaming now</h2>
          </div>
          <small>{visibleRooms.length} live</small>
        </div>

        {visibleRooms.length > 0 ? (
          <div className="fv-discover-live-grid">
            {visibleRooms.map((room) => {
              const host = room.host || {}
              const initial = creatorInitial(host)
              return (
                <button
                  key={room.id}
                  type="button"
                  className="fv-discover-live-card"
                  onClick={() => openLiveRoom(room)}
                  aria-label={`Watch ${host.displayName || host.username || 'creator'} live`}
                >
                  <span className="fv-discover-live-art">
                    {host.avatarUrl ? <img src={host.avatarUrl} alt="" /> : <b>{initial}</b>}
                    <span className="fv-discover-live-glow" aria-hidden="true" />
                    <span className="fv-discover-live-badge">LIVE</span>
                    <span className="fv-discover-live-fame"><i aria-hidden="true">F</i>{formatStat(room.fameTaps)}</span>
                  </span>
                  <span className="fv-discover-live-copy">
                    <strong>{room.title || 'Live on Fameverse'}</strong>
                    <small>{creatorHandle(host)}</small>
                  </span>
                </button>
              )
            })}
          </div>
        ) : (
          <div className="fv-discover-empty">
            <span className="fv-discover-empty-mark" aria-hidden="true">F</span>
            <strong>
              {liveDiscovery?.state === 'loading'
                ? 'Checking Fameverse Live…'
                : liveDiscovery?.state === 'degraded'
                  ? 'Live discovery is reconnecting…'
                  : filter === 'For You'
                    ? 'No creators are live right now'
                    : `No ${filter.toLowerCase()} creators are live right now`}
            </strong>
            <p>Only real active rooms appear here. No demo streams or fake viewer counts.</p>
          </div>
        )}
      </section>

      <section className="fv-discover-section fv-discover-recommended" aria-labelledby="recommended-title">
        <div className="fv-discover-section-heading">
          <div>
            <span>COMMUNITY</span>
            <h2 id="recommended-title">Recommended creators</h2>
          </div>
        </div>

        {visibleCreators.length > 0 ? (
          <div className="fv-discover-creator-list">
            {visibleCreators.map((creator) => {
              const isFollowing = followingIds.has(creator.id)
              const busy = followNetwork?.busyTargetId === creator.id
              return (
                <article className="fv-discover-creator" key={creator.id}>
                  <span className="fv-discover-creator-avatar">
                    {creator.avatarUrl ? <img src={creator.avatarUrl} alt="" /> : <b>{creatorInitial(creator)}</b>}
                  </span>
                  <div className="fv-discover-creator-copy">
                    <strong>{creator.displayName}</strong>
                    <small>{creatorHandle(creator)} · {formatStat(creator.followerCount)} followers</small>
                    {creator.bio && <p>{creator.bio}</p>}
                  </div>
                  <button
                    type="button"
                    className={isFollowing ? 'is-following' : ''}
                    disabled={busy}
                    onClick={() => followNetwork?.toggleFollow?.(creator.id)}
                  >
                    {isFollowing ? 'Following' : 'Follow'}
                  </button>
                </article>
              )
            })}
          </div>
        ) : (
          <div className="fv-discover-creators-empty">
            <strong>{creatorDiscovery?.state === 'degraded' ? 'Creator discovery is reconnecting…' : 'No matching creators yet'}</strong>
            <small>Try another search or switch back to For You.</small>
          </div>
        )}
      </section>
    </section>
  )
}
