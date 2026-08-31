import { FAMEVERSE_RELEASE } from '../../config/version.js'

export default function TopBar({ standalone, installPwa }) {
  return (
    <header className="topbar fam-topbar">
      <div>
        <div className="beta-chip fam-release-chip-top">{FAMEVERSE_RELEASE.label}</div>
        <h1>FAMEVERSE <span>LIVE</span></h1>
      </div>
      {!standalone && <button className="install-btn" onClick={installPwa}>Install PWA</button>}
    </header>
  )
}
