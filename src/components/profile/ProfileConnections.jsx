export default function ProfileConnections({
  mode,
  followers,
  following,
  busyTargetId,
  toggleFollow,
  onClose,
}) {
  if (!mode) return null

  const friends = followers.filter((item) => item.relation?.key === 'friend')
  const items = mode === 'followers' ? followers : mode === 'friends' ? friends : following
  const title = mode === 'followers' ? 'Followers' : mode === 'friends' ? 'Friends' : 'Following'

  return (
    <section className="profile-connections" aria-label={title}>
      <div className="profile-connections-heading">
        <div>
          <span>NETWORK</span>
          <strong>{title}</strong>
        </div>
        <button type="button" onClick={onClose}>Done</button>
      </div>

      {items.length ? (
        <div className="profile-connections-list">
          {items.map((item) => {
            const initial = (item.display_name || item.username || 'F').trim().charAt(0).toUpperCase()
            return (
              <div className="profile-connection-row" key={item.id}>
                {item.avatar_url
                  ? <img className="avatar profile-connection-avatar" src={item.avatar_url} alt="" />
                  : <div className="avatar profile-connection-avatar">{initial}</div>}
                <div className="profile-connection-copy">
                  <strong>{item.display_name || 'Fameverse User'}</strong>
                  <small>{item.username ? `@${item.username}` : '@newuser'}</small>
                </div>
                <button
                  type="button"
                  className={`profile-relation-button relation-${item.relation.key}`}
                  disabled={busyTargetId === item.id}
                  onClick={() => toggleFollow(item.id)}
                >
                  {busyTargetId === item.id ? '…' : item.relation.label}
                </button>
              </div>
            )
          })}
        </div>
      ) : (
        <div className="profile-connections-empty">
          <span>◎</span>
          <strong>No {title.toLowerCase()} yet</strong>
          <p>{mode === 'followers' ? 'People who follow you will appear here.' : mode === 'friends' ? 'Mutual follows become Fameverse friends.' : 'People you follow will appear here.'}</p>
        </div>
      )}
    </section>
  )
}
