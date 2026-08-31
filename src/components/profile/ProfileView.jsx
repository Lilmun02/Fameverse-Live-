import { useState } from 'react'
import { creatorContent } from '../../config/creator.js'
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
    <section className="panel full-panel profile-panel refined-profile">
      <div className="profile-toolbar">
        <span className="profile-brand">FAMEVERSE</span>
        <button aria-label="Settings" onClick={() => openProfileMode('settings')}>⚙</button>
      </div>

      <div className="profile-cover">
        <div className="avatar profile-avatar refined-avatar">{initial}</div>
      </div>

      <div className="profile-identity">
        <span className="creator-badge">BETA CREATOR</span>
        <h2>{displayName}</h2>
        <p>{username}</p>
        <p className="profile-bio">{profile?.bio || 'Add a bio so viewers know who you are.'}</p>
        <div className="profile-meta"><span>Joined {joinedLabel}</span><span>Live creator</span></div>
      </div>

      <div className="profile-stats refined-stats">
        <button type="button" onClick={() => setConnectionsMode('followers')}>
          <strong>{followerCount}</strong><small>Followers</small>
        </button>
        <button type="button" onClick={() => setConnectionsMode('following')}>
          <strong>{followingCount}</strong><small>Following</small>
        </button>
        <div><strong>0</strong><small>Likes</small></div>
      </div>

      <ProfileConnections
        mode={connectionsMode}
        followers={followers}
        following={following}
        busyTargetId={busyTargetId}
        toggleFollow={toggleFollow}
        onClose={() => setConnectionsMode(null)}
      />

      <div className="profile-actions refined-actions">
        <button className="primary-profile-action" onClick={() => openProfileMode('edit')}>Edit profile</button>
        <button onClick={shareRoom}>Share profile</button>
      </div>

      <button className="creator-hub-card creator-hub-button" onClick={() => openProfileMode('studio')}>
        <div>
          <span>CREATOR HUB</span>
          <strong>Creator Studio</strong>
          <small>Manage your live setup, creator tools and beta status.</small>
        </div>
        <b>→</b>
      </button>

      <div className="profile-content-tabs" role="tablist" aria-label="Creator content">
        {Object.keys(creatorContent).map((key) => (
          <button key={key} className={creatorTab === key ? 'active' : ''} onClick={() => setCreatorTab(key)}>{creatorContent[key][0]}</button>
        ))}
      </div>

      <div className="profile-empty-content">
        <span>{creatorTab === 'gifts' ? '🎁' : creatorTab === 'replays' ? '↻' : '✦'}</span>
        <strong>{creatorSectionTitle}</strong>
        <p>{creatorSectionCopy}</p>
      </div>

      <div className="compact-beta-note">Beta: test coins remain local and are not displayed as public creator earnings.</div>
    </section>
  )
}
