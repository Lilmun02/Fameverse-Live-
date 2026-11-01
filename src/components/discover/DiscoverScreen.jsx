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
  creatorDiscovery,
  followNetwork,
  currentProfile,
}) {
  const [filter, setFilter] = useState('For You')
  const [query, setQuery] = useState('')
  const normalizedQuery = query.trim().toLowerCase()
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

  const visibleCreators = useMemo(() => creators.filter((creator) => {
    if (!filterAllows(creator.id)) return false
    return matchesQuery(normalizedQuery, [
      creator.displayName,
      creator.username,
      creator.bio,
    ])
  }), [creators, filter, friendIds, followingIds, normalizedQuery])

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
          placeholder="Search creators"
          aria-label="Search creators"
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
