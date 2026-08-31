import { useState } from 'react'

const FILTERS = ['Popular', 'Friends', 'Following', 'Nearby']

export default function DiscoverScreen({ setTab }) {
  const [filter, setFilter] = useState('Popular')
  const [query, setQuery] = useState('')

  return (
    <section className="community-discover-shell" aria-labelledby="discover-title">
      <header className="community-discover-header">
        <div>
          <span>LIVE DISCOVERY</span>
          <h1 id="discover-title">Find your people</h1>
        </div>
        <button type="button" className="community-discover-profile" onClick={() => setTab('profile')} aria-label="Open profile">♙</button>
      </header>

      <div className="community-discover-filters" role="tablist" aria-label="Live discovery filters">
        {FILTERS.map((item) => (
          <button
            type="button"
            role="tab"
            aria-selected={filter === item}
            className={filter === item ? 'active' : ''}
            key={item}
            onClick={() => setFilter(item)}
          >
            {item}
          </button>
        ))}
      </div>

      <label className="community-discover-search">
        <span aria-hidden="true">⌕</span>
        <input
          type="search"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search creators or live titles"
          aria-label="Search live discovery"
        />
      </label>

      <div className="community-live-heading">
        <div>
          <span>{filter.toUpperCase()}</span>
          <strong>Live now</strong>
        </div>
        <small>0 live</small>
      </div>

      <div className="community-live-empty">
        <div className="community-live-empty-mark" aria-hidden="true">◉</div>
        <strong>No live rooms to show yet</strong>
        <p>Real public creators will appear here when live-room discovery is connected. We are not filling the grid with fake accounts.</p>
        <button type="button" onClick={() => setTab('live')}>Go Live</button>
      </div>
    </section>
  )
}
