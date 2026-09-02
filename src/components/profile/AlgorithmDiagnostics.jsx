import { getTapIntegrityStatus } from '../../features/taps/tapIntegrity.js'
import { getVerseMomentumStatus } from '../../features/ranking/verseMomentum.js'

export default function AlgorithmDiagnostics() {
  const status = getVerseMomentumStatus()
  const tapStatus = getTapIntegrityStatus()

  return (
    <section className="algorithm-diagnostics" aria-label="Verse Momentum diagnostics">
      <header>
        <div>
          <span>FAM ALGORITHM 1.2</span>
          <h3>Verse Momentum</h3>
        </div>
        <b className="algorithm-status-off">Ranking OFF</b>
      </header>

      <p>Three equal discovery lanes stay locked: Audience, Taps and Gift Coins. Raw Fame Taps are uncapped; the server tap ledger stores visible taps separately from ranking-eligible taps.</p>

      <div className="algorithm-diagnostic-grid">
        <div><strong>{status.rankingSignalCount}</strong><small>Equal ranking lanes</small></div>
        <div><strong>∞</strong><small>Raw Fame Tap cap</small></div>
        <div><strong>0</strong><small>Follower ranking points</small></div>
      </div>

      <footer>
        <span>{tapStatus.version} · SERVER LEDGER</span>
        <small>{tapStatus.viewerCaptureConnected ? 'Viewer tap capture connected.' : 'Authoritative tap ledger ready · visible Live totals connected · viewer tap capture waits for the real viewer Live surface.'}</small>
      </footer>
    </section>
  )
}
