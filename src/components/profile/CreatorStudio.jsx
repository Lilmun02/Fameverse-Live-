import AlgorithmDiagnostics from './AlgorithmDiagnostics.jsx'

export default function CreatorStudio({ openProfileMode, setTab, setCreatorTab, setProfileMode }) {
  return (
    <section className="panel full-panel account-panel creator-studio-page">
      <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
      <span className="eyebrow">CREATOR STUDIO · BETA</span>
      <h2>Creator Studio</h2>
      <p className="studio-intro">Your creator workspace stays inside Profile. Nothing here should throw you back into Live unless you choose to open the live setup.</p>

      <div className="studio-grid">
        <button onClick={() => setTab('live')}><span>●</span><strong>Open live setup</strong><small>Camera, microphone, gifts and live controls</small></button>
        <button onClick={() => { setCreatorTab('clips'); setProfileMode('view') }}><span>✦</span><strong>Clips</strong><small>Creator clips are being connected</small></button>
        <button onClick={() => { setCreatorTab('replays'); setProfileMode('view') }}><span>↻</span><strong>Replays</strong><small>Replay library arrives with real rooms</small></button>
        <button onClick={() => { setCreatorTab('gifts'); setProfileMode('view') }}><span>🎁</span><strong>Gift activity</strong><small>Test gifts now, production wallet later</small></button>
      </div>

      <AlgorithmDiagnostics />

      <div className="settings-info-card">
        <b>Creator status</b>
        <p>Account and profile are real backend data. Remote broadcasting, creator earnings, payouts, analytics and moderation dashboards are still under construction.</p>
      </div>
    </section>
  )
}
