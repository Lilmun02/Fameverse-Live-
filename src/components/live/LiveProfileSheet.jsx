function stopLiveTap(event) {
  event.stopPropagation()
}

function initialFor(name) {
  return String(name || 'F').trim().charAt(0).toUpperCase() || 'F'
}

export default function LiveProfileSheet({ sheet, currentUserId, followNetwork }) {
  if (!sheet?.isOpen) return null

  const profile = sheet.profile
  const isSelf = Boolean(currentUserId && sheet.userId === currentUserId)
  const isFollowing = Boolean(followNetwork?.following?.some((item) => item.id === sheet.userId))
  const busy = followNetwork?.busyTargetId === sheet.userId

  const toggleFollow = async () => {
    if (isSelf || !sheet.userId || busy) return
    await followNetwork?.toggleFollow?.(sheet.userId)
    sheet.refresh?.()
  }

  return (
    <div className="live-sheet-backdrop fv-live-profile-backdrop" onPointerDown={stopLiveTap} onClick={sheet.close}>
      <section
        className="live-sheet fv-live-profile-sheet"
        role="dialog"
        aria-modal="true"
        aria-label="Fameverse profile"
        onClick={stopLiveTap}
        onPointerDown={stopLiveTap}
      >
        <div className="sheet-handle" aria-hidden="true" />
        <div className="sheet-heading">
          <div>
            <span>PROFILE</span>
            <strong>{profile?.displayName || 'Fameverse User'}</strong>
          </div>
          <button type="button" onClick={sheet.close}>Close</button>
        </div>

        {sheet.status === 'loading' && <p>Loading profile…</p>}
        {sheet.status === 'missing' && <p>This account profile is not available.</p>}
        {sheet.status === 'error' && <p>Could not load this profile.</p>}

        {sheet.status === 'ready' && profile && (
          <div className="fv-live-profile-body">
            {profile.avatarUrl ? (
              <img className="fv-live-profile-avatar" src={profile.avatarUrl} alt="" />
            ) : (
              <span className="fv-live-profile-avatar is-fallback">{initialFor(profile.displayName)}</span>
            )}
            <strong>{profile.displayName}</strong>
            {profile.username && <small>@{profile.username}</small>}
            <span className="fam-gifter-level">Lv. {Math.max(1, Number(profile.gifterLevel || 1))}</span>
            {profile.bio ? <p>{profile.bio}</p> : null}
            <div className="fv-live-profile-counts">
              <span><b>{profile.followerCount}</b> Followers</span>
              <span><b>{profile.followingCount}</b> Following</span>
            </div>
            {!isSelf && (
              <button
                type="button"
                className={`fv-live-profile-follow ${isFollowing ? 'is-following' : ''}`}
                disabled={busy}
                onClick={toggleFollow}
              >
                {busy ? '…' : isFollowing ? 'Following' : 'Follow'}
              </button>
            )}
          </div>
        )}
      </section>
    </div>
  )
}
