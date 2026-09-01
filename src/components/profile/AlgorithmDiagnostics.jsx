import { MAX_RANKING_TAPS_PER_USER } from '../../features/ranking/verseMomentumConfig.js'
import { getVerseMomentumStatus } from '../../features/ranking/verseMomentum.js'

export default function AlgorithmDiagnostics() {
  const status = getVerseMomentumStatus()

  return (
    <section className="algorithm-diagnostics" aria-label="Verse Momentum diagnostics">
      <header>
        <div>
          <span>FAM ALGORITHM 1.1</span>
          <h3>Verse Momentum</h3>
        </div>
        <b className="algorithm-status-off">Ranking OFF</b>
      </header>

      <p>Three equal discovery lanes are locked: Audience, Taps and Gift Coins. Followers, comments and watch-time telemetry do not add ranking points in this version.</p>

      <div className="algorithm-diagnostic-grid">
        <div><strong>{status.rankingSignalCount}</strong><small>Equal ranking lanes</small></div>
        <div><strong>{MAX_RANKING_TAPS_PER_USER}</strong><small>Eligible taps / user / Live</small></div>
        <div><strong>0</strong><small>Follower ranking points</small></div>
      </div>

      <footer>
        <span>{status.version}</span>
        <small>Gift type does not change ranking power. Real Discover ranking stays off until Live rooms are connected.</small>
      </footer>
    </section>
  )
}
