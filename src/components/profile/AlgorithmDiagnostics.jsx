import { VERSE_EVENT_TYPES } from '../../features/ranking/eventContract.js'
import { MAX_RANKING_TAPS_PER_USER } from '../../features/ranking/verseMomentumConfig.js'
import { getVerseMomentumStatus, scoreVerseMomentum } from '../../features/ranking/verseMomentum.js'

const SAMPLE_EVENTS = [
  ...Array.from({ length: 12 }, (_, index) => ({ type: VERSE_EVENT_TYPES.VIEWER_JOIN, actorId: `demo-${index + 1}` })),
  ...Array.from({ length: 12 }, (_, index) => ({ type: VERSE_EVENT_TYPES.WATCH_TIME, actorId: `demo-${index + 1}`, value: 120 })),
  ...Array.from({ length: 4 }, (_, index) => ({ type: VERSE_EVENT_TYPES.COMMENT, actorId: `demo-${index + 1}` })),
  ...Array.from({ length: 2 }, (_, index) => ({ type: VERSE_EVENT_TYPES.FOLLOW, actorId: `demo-${index + 1}` })),
  ...Array.from({ length: 4 }, (_, index) => ({ type: VERSE_EVENT_TYPES.TAP, actorId: `demo-${index + 1}`, value: 20 })),
  { type: VERSE_EVENT_TYPES.GIFT, actorId: 'demo-1', value: 100 },
]

export default function AlgorithmDiagnostics() {
  const status = getVerseMomentumStatus()
  const diagnostic = scoreVerseMomentum(SAMPLE_EVENTS)

  return (
    <section className="algorithm-diagnostics" aria-label="Verse Momentum diagnostics">
      <header>
        <div>
          <span>FAM ALGORITHM 1</span>
          <h3>Verse Momentum</h3>
        </div>
        <b className="algorithm-status-off">Ranking OFF</b>
      </header>

      <p>The scoring engine is installed and guarded, but it is not ranking Discover yet.</p>

      <div className="algorithm-diagnostic-grid">
        <div><strong>{status.signalCount}</strong><small>Signals defined</small></div>
        <div><strong>{diagnostic.score}</strong><small>Diagnostic score</small></div>
        <div><strong>{MAX_RANKING_TAPS_PER_USER}</strong><small>Tap cap / user</small></div>
      </div>

      <footer>
        <span>{status.version}</span>
        <small>Simulation only · no real creator ranking is active.</small>
      </footer>
    </section>
  )
}
