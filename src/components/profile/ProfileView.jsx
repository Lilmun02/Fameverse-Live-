import { useState } from 'react'
import { FAMEVERSE_RELEASE } from '../../config/version.js'
import ProfileConnections from './ProfileConnections.jsx'

export default function ProfileView({
  initial,
  displayName,
  username,
  profile,
  openProfileMode,
  followers,
  following,
  followerCount,
  followingCount,
  busyTargetId,
  toggleFollow,
  gifterLevel = 1,
}) {
  const [connectionsMode, setConnectionsMode] = useState(null)
  const friendCount = followers.filter((person) => person.relation?.key === 'friend').length
  const level = Math.max(1, Number(gifterLevel || 1))

  return (
    <section className="panel full-panel profile-panel refined-profile fv-profile">
      <div className="fv-profile-topbar">
        <div><span>{FAMEVERSE_RELEASE.family}</span><strong>Profile</strong></div>
        <button type="button" aria-label="Settings" onClick={() => openProfileMode('settings')}>⚙</button>
      </div>

      <div className="fv-profile-cover" aria-hidden="true" />

      <div className="fv-profile-main">
        <div className="fv-profile-avatar-wrap">
          {profile?.avatar_url ? <img className="fv-profile-avatar" src={profile.avatar_url} alt={`${displayName} profile`} /> : <div className="fv-profile-avatar fallback">{initial}</div>}
          <button type="button" className="fv-profile-avatar-edit" onClick={() => openProfileMode('edit')} aria-label="Edit profile photo">✎</button>
        </div>

        <div className="fv-profile-identity">
          <h1>{displayName}</h1>
          <span>{username}</span>
          <div className="fv-profile-badges" aria-label="Fameverse identity badges">
            <span className="fv-profile-level">✦ Lv. {level}</span>
          </div>
          <p>{profile?.bio || 'Add a bio so people know what you are about.'}</p>
        </div>

        <div className="fv-profile-stats">
          <button type="button" onClick={() => setConnectionsMode('following')}><strong>{followingCount}</strong><span>Following</span></button>
          <button type="button" onClick={() => setConnectionsMode('followers')}><strong>{followerCount}</strong><span>Followers</span></button>
          <div><strong>{friendCount}</strong><span>Friends</span></div>
        </div>

        <ProfileConnections mode={connectionsMode} followers={followers} following={following} busyTargetId={busyTargetId} toggleFollow={toggleFollow} onClose={() => setConnectionsMode(null)} />

        <div className="fv-profile-actions single">
          <button type="button" className="primary" onClick={() => openProfileMode('edit')}>Edit profile</button>
        </div>

        <div className="fv-profile-identity-card">
          <div>
            <span>GIFTER IDENTITY</span>
            <strong>Gifter Level {level}</strong>
            <p>Your Fameverse gifting level stays attached to your identity as you support creators.</p>
          </div>
          <div className="fv-profile-level-orb" aria-hidden="true">{level}</div>
        </div>

        <button type="button" className="fv-studio-row" onClick={() => openProfileMode('studio')}>
          <div><span>CREATOR TOOLS</span><strong>Creator Studio</strong></div><b>›</b>
        </button>
      </div>
    </section>
  )
}
