const FILTERS = ['Popular', 'Friends', 'Following', 'Nearby']

export default function DiscoverScreen({ setTab }) {
  return (
    <section className="fv-discover" aria-labelledby="discover-title">
      <header className="fv-discover-topbar">
        <div><span>COMMUNITY</span><h1 id="discover-title">Discover</h1></div>
        <button type="button" className="fv-discover-profile" onClick={() => setTab('profile')} aria-label="Open profile">♙</button>
      </header>

      <div className="fv-discover-filters" role="tablist" aria-label="Discovery filters">
        {FILTERS.map((label, index) => <button key={label} type="button" className={index === 0 ? 'active' : ''}>{label}</button>)}
      </div>

      <label className="fv-discover-search">
        <span aria-hidden="true">⌕</span>
        <input type="search" placeholder="Search creators or live titles" aria-label="Search discovery" />
      </label>

      <section className="fv-live-section">
        <div className="fv-live-section-heading">
          <div><span>LIVE NOW</span><h2>Community live</h2></div>
          <small>0 live</small>
        </div>

        <div className="fv-live-empty">
          <div className="fv-live-empty-mark" aria-hidden="true"><i /></div>
          <strong>No one is live yet</strong>
          <p>When a real creator starts a public room, it will appear here.</p>
        </div>
      </section>
    </section>
  )
}
