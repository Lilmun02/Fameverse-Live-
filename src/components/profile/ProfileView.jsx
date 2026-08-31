import { useState } from 'react'
import { creatorContent } from '../../config/creator.js'
import { FAMEVERSE_RELEASE } from '../../config/version.js'
import ProfileConnections from './ProfileConnections.jsx'

export default function ProfileView({
  initial,
  displayName,
  username,
  profile,
  joinedLabel,
  openProfileMode,
  shareRoom,
  creatorTab,
  setCreatorTab,
  followers,
  following,
  followerCount,
  followingCount,
  busyTargetId,
  toggleFollow,
}) {
  const [connectionsMode, setConnectionsMode] = useState(null)
  const [creatorSectionTitle, creatorSectionCopy] = creatorContent[creatorTab]

  return (
    <section className="panel full-panel profile-panel refined-profile fv-profile">
      <div className="fv-profile-topbar">
        <div><span>{FAMEVERSE_RELEASE.family}</span><strong>Profile</strong></div>
        <button type="button" aria-label="Settings" onClick={() => openProfileMode('settings')}>⚙</button>
      </div>

      <div className="fv-profile-cover" />

      <div className="fv-profile-main">
        {profile?.avatar_url ? <img className="fv-profile-avatar" src={profile.avatar_url} alt="" /> : <div className="fv-profile-avatar fallback">{initial}</div>}
        <div className="fv-profile-identity">
          <h1>{displayName}</h1><span>{username}</span>
          <p>{profile?.bio || 'Add a bio so people know what you are about.'}</p>
          <small>Joined {joinedLabel}</small>
        </div>

        <div className="fv-profile-stats">
          <button type="button" onClick={() => setConnectionsMode('followers')}><strong>{followerCount}</strong><span>Followers</span></button>
          <button type="button" onClick={() => setConnectionsMode('following')}><strong>{followingCount}</strong><span>Following</span></button>
          <div><strong>0</strong><span>Likes</span></div>
        </div>

        <ProfileConnections mode={connectionsMode} followers={followers} following={following} busyTargetId={busyTargetId} toggleFollow={toggleFollow} onClose={() => setConnectionsMode(null)} />

        <div className="fv-profile-actions">
          <button type="button" className="primary" onClick={() => openProfileMode('edit')}>Edit profile</button>
          <button type="button" onClick={shareRoom}>Share</button>
        </div>

        <button type="button" className="fv-studio-row" onClick={() => openProfileMode('studio')}>
          <div><span>CREATOR TOOLS</span><strong>Creator Studio</strong></div><b>›</b>
        </button>

        <div className="fv-profile-tabs" role="tablist" aria-label="Creator content">
          {Object.keys(creatorContent).map((key) => <button key={key} className={creatorTab === key ? 'active' : ''} onClick={() => setCreatorTab(key)}>{creatorContent[key][0]}</button>)}
        </div>

        <div className="fv-profile-empty">
          <span>{creatorTab === 'gifts' ? '🎁' : creatorTab === 'replays' ? '↻' : '✦'}</span>
          <strong>{creatorSectionTitle}</strong><p>{creatorSectionCopy}</p>
        </div>
      </div>
    </section>
  )
}
