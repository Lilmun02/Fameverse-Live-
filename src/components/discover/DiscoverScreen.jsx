import { useMemo, useState } from 'react'

const FILTERS = ['Popular', 'Friends', 'Following', 'Nearby']

const EMPTY_COPY = {
  Popular: ['No one is live yet', 'When a real creator starts a public room, it will appear here.'],
  Friends: ['No friends are live yet', 'When one of your mutual friends starts a public room, it will appear here.'],
  Following: ['Nobody you follow is live yet', 'When a creator you follow starts a public room, it will appear here.'],
  Nearby: ['No nearby live rooms yet', 'Nearby discovery will populate from real public rooms when location-based discovery is connected.'],
}

export default function DiscoverScreen({ setTab, liveDiscovery, onOpenLiveRoom }) {
  const [filter, setFilter] = useState('Popular')
  const [query, setQuery] = useState('')
  const [emptyTitle, emptyBody] = EMPTY_COPY[filter]
  const rooms = liveDiscovery?.rooms || []

  const visibleRooms = useMemo(() => {
    if (filter !== 'Popular') return []
    const normalizedQuery = query.trim().toLowerCase()
    if (!normalizedQuery) return rooms

    return rooms.filter((room) => {
      const searchable = [room.title, room.host?.displayName, room.host?.username]
        .filter(Boolean)
        .join(' ')
        .toLowerCase()
      return searchable.includes(normalizedQuery)
    })
  }, [filter, query, rooms])

  const openLiveRoom = (room) => {
    window.FameverseGiftEngine?.startAudioSession?.()
    onOpenLiveRoom?.(room)
  }

  return (
    <section className="fv-discover" aria-labelledby="discover-title">
      <header className="fv-discover-topbar">
        <div><span>COMMUNITY</span><h1 id="discover-title">Discover</h1></div>
        <button type="button" className="fv-discover-profile" onClick={() => setTab('profile')} aria-label="Open profile">♙</button>
      </header>

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

      <label className="fv-discover-search">
        <span aria-hidden="true">⌕</span>
        <input
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search creators or live titles"
          aria-label="Search discovery"
        />
      </label>

      <section className="fv-live-section">
        <div className="fv-live-section-heading">
          <div><span>{filter.toUpperCase()}</span><h2>Community live</h2></div>
          <small>{visibleRooms.length} live</small>
        </div>

        {filter === 'Popular' && visibleRooms.length > 0 ? (
          <div className="fv-live-room-list">
            {visibleRooms.map((room) => {
              const hostLabel = room.host?.username
                ? `@${room.host.username}`
                : room.host?.displayName || 'Fameverse creator'
              const initial = (room.host?.displayName || room.host?.username || 'F').trim().charAt(0).toUpperCase()

              return (
                <button
                  key={room.id}
                  type="button"
                  className="fv-live-room-row"
                  onClick={() => openLiveRoom(room)}
                >
                  <span className="fv-live-room-avatar" aria-hidden="true">{initial}</span>
                  <span className="fv-live-room-copy">
                    <b>{room.title}</b>
                    <small>{hostLabel} · LIVE</small>
                  </span>
                  <span className="fv-live-room-enter">Watch ›</span>
                </button>
              )
            })}
          </div>
        ) : (
          <div className="fv-live-empty">
            <div className="fv-live-empty-mark" aria-hidden="true"><i /></div>
            <strong>
              {liveDiscovery?.state === 'loading' && filter === 'Popular'
                ? 'Checking live rooms…'
                : liveDiscovery?.state === 'degraded' && filter === 'Popular'
                  ? 'Live discovery is reconnecting…'
                  : emptyTitle}
            </strong>
            <p>{emptyBody}</p>
          </div>
        )}
      </section>
    </section>
  )
}
