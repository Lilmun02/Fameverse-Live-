import { useState } from 'react'

const FILTERS = ['Popular', 'Friends', 'Following', 'Nearby']

const EMPTY_COPY = {
  Popular: ['No one is live yet', 'When a real creator starts a public room, it will appear here.'],
  Friends: ['No friends are live yet', 'When one of your mutual friends starts a public room, it will appear here.'],
  Following: ['Nobody you follow is live yet', 'When a creator you follow starts a public room, it will appear here.'],
  Nearby: ['No nearby live rooms yet', 'Nearby discovery will populate from real public rooms when location-based discovery is connected.'],
}

export default function DiscoverScreen({ setTab }) {
  const [filter, setFilter] = useState('Popular')
  const [query, setQuery] = useState('')
  const [emptyTitle, emptyBody] = EMPTY_COPY[filter]

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
          <small>0 live</small>
        </div>

        <div className="fv-live-empty">
          <div className="fv-live-empty-mark" aria-hidden="true"><i /></div>
          <strong>{emptyTitle}</strong>
          <p>{emptyBody}</p>
        </div>
      </section>
    </section>
  )
}
