import { useState } from 'react'
import { FAMEVERSE_RELEASE } from '../../config/version.js'
import { isPrivilegedIdentityRole } from '../../services/accountRoles.js'
import GifterBadge from './GifterBadge.jsx'
import ProfileConnections from './ProfileConnections.jsx'

export default function ProfileView({ initial, displayName, username, profile, openProfileMode, followers, following, followerCount, followingCount, busyTargetId, toggleFollow, gifterStats }) {
  const [connectionsMode, setConnectionsMode] = useState(null)
  const friends = followers.filter((person) => person.relation?.key === 'friend')
  const totalCoinsSent = Math.max(0, Number(gifterStats?.totalCoinsSent || 0))
  const gifterLevel = Math.max(1, Number(gifterStats?.level || 1))
  const hideGifterBadge = isPrivilegedIdentityRole(profile?.account_role)

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
          {totalCoinsSent > 0 && !hideGifterBadge && (
            <div className="fv-profile-badges" aria-label="Earned Fameverse identity badge">
              <GifterBadge level={gifterLevel} size="small" totalCoinsSent={totalCoinsSent} />
            </div>
          )}
          <p>{profile?.bio || 'Add a bio so people know what you are about.'}</p>
        </div>
        <div className="fv-profile-stats">
          <button type="button" onClick={() => setConnectionsMode('following')}><strong>{followingCount}</strong><span>Following</span></button>
          <button type="button" onClick={() => setConnectionsMode('followers')}><strong>{followerCount}</strong><span>Followers</span></button>
          <button type="button" onClick={() => setConnectionsMode('friends')}><strong>{friends.length}</strong><span>Friends</span></button>
        </div>
        <ProfileConnections mode={connectionsMode} followers={followers} following={following} busyTargetId={busyTargetId} toggleFollow={toggleFollow} onClose={() => setConnectionsMode(null)} />
        <div className="fv-profile-actions single"><button type="button" className="primary" onClick={() => openProfileMode('edit')}>Edit profile</button></div>
        <button type="button" className="fv-studio-row" onClick={() => openProfileMode('studio')}><div><span>CREATOR TOOLS</span><strong>Creator Studio</strong></div><b>›</b></button>
      </div>
    </section>
  )
}
