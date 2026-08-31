import { FAMEVERSE_RELEASE } from '../../config/version.js'

export default function DiscoverScreen() {
  return (
    <section className="fam-discover-shell" aria-labelledby="discover-title">
      <div className="fam-discover-hero">
        <div className="fam-discover-copy">
          <span className="fam-discover-kicker">DISCOVER · {FAMEVERSE_RELEASE.family}</span>
          <h2 id="discover-title">Live in the Verse</h2>
          <p>Real public rooms will land here as Fameverse discovery comes online. No fake creators, fake viewers, or placeholder lives.</p>
        </div>
        <div className="fam-discover-orbit" aria-hidden="true">
          <span className="fam-discover-orbit-ring ring-one" />
          <span className="fam-discover-orbit-ring ring-two" />
          <b>F</b>
        </div>
      </div>

      <div className="fam-discover-status-grid">
        <article>
          <span>PUBLIC ROOMS</span>
          <strong>0</strong>
          <small>Realtime room discovery is not connected yet.</small>
        </article>
        <article>
          <span>DISCOVERY MODE</span>
          <strong>Beta</strong>
          <small>Only verified live data will populate this page.</small>
        </article>
      </div>

      <div className="fam-discover-section">
        <div className="fam-discover-section-heading">
          <div>
            <span>LIVE IN THE VERSE</span>
            <strong>No public rooms yet</strong>
          </div>
          <span className="fam-discover-zero">0 LIVE</span>
        </div>
        <div className="fam-discover-empty-card">
          <div className="fam-empty-pulse" aria-hidden="true">✦</div>
          <strong>The Verse is quiet right now</strong>
          <p>When real creators go public, their rooms will appear here instead of made-up demo profiles.</p>
        </div>
      </div>

      <div className="fam-discover-footer-note">
        <span>{FAMEVERSE_RELEASE.label}</span>
        <p>Discovery cards, ranking, and creator recommendations stay locked until they can be powered by real Fameverse activity.</p>
      </div>
    </section>
  )
}
