export default function TopBar({ standalone, installPwa }) {
  return (
    <header className="topbar">
      <div>
        <div className="beta-chip">BETA 0.2</div>
        <h1>FAMEVERSE <span>LIVE</span></h1>
      </div>
      {!standalone && <button className="install-btn" onClick={installPwa}>Install PWA</button>}
    </header>
  )
}
