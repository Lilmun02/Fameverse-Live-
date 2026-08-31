import { useMemo, useState } from 'react'
import { FAMEVERSE_RELEASE } from '../../config/version.js'

const GROUPS = [
  ['friends', 'Friends'],
  ['following', 'Following'],
  ['followers', 'Followers'],
]

function uniqueProfiles(items) {
  return [...new Map(items.map((item) => [item.id, item])).values()]
}

export default function HomeScreen({
  displayName,
  username,
  initial,
  followNetwork,
  setTab,
  standalone,
  installPwa,
}) {
  const [group, setGroup] = useState('friends')
  const [query, setQuery] = useState('')

  const friends = useMemo(
    () => uniqueProfiles([
      ...followNetwork.followers.filter((item) => item.relation.key === 'friend'),
      ...followNetwork.following.filter((item) => item.relation.key === 'friend'),
    ]),
    [followNetwork.followers, followNetwork.following],
  )

  const groups = {
    friends,
    following: followNetwork.following,
    followers: followNetwork.followers,
  }

  const visiblePeople = useMemo(() => {
    const needle = query.trim().toLowerCase()
    if (!needle) return groups[group]
    return groups[group].filter((person) => (
      person.display_name?.toLowerCase().includes(needle)
      || person.username?.toLowerCase().includes(needle)
    ))
  }, [friends, followNetwork.followers, followNetwork.following, group, query])

  return (
    <section className="community-home-shell" aria-labelledby="community-home-title">
      <header className="community-home-header">
        <div>
          <span className="community-version">{FAMEVERSE_RELEASE.family}</span>
          <h1 id="community-home-title">FAMEVERSE</h1>
        </div>
        <button className="community-profile-button" type="button" onClick={() => setTab('profile')} aria-label="Open profile">
          <span>{initial}</span>
        </button>
      </header>

      <div className="community-welcome-row">
        <div>
          <span>YOUR COMMUNITY</span>
          <strong>{displayName}</strong>
          <small>{username}</small>
        </div>
        {!standalone && (
          <button type="button" className="community-install-button" onClick={installPwa}>Install</button>
        )}
      </div>

      <div className="community-filter-row" role="tablist" aria-label="Community connections">
        {GROUPS.map(([key, label]) => (
          <button
            type="button"
            role="tab"
            aria-selected={group === key}
            className={group === key ? 'active' : ''}
            key={key}
            onClick={() => setGroup(key)}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="community-search-row">
        <label className="community-search-box">
          <span aria-hidden="true">⌕</span>
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search your people"
            aria-label="Search your community"
          />
        </label>
        <button type="button" className="community-discover-button" onClick={() => setTab('discover')} aria-label="Open live discovery">✦</button>
      </div>

      <div className="community-stats-row" aria-label="Community stats">
        <div><strong>{friends.length}</strong><small>Friends</small></div>
        <div><strong>{followNetwork.followingCount}</strong><small>Following</small></div>
        <div><strong>{followNetwork.followerCount}</strong><small>Followers</small></div>
      </div>

      <section className="community-people-section">
        <div className="community-section-heading">
          <div>
            <span>{GROUPS.find(([key]) => key === group)?.[1] || 'Community'}</span>
            <strong>Your people</strong>
          </div>
          <small>{visiblePeople.length}</small>
        </div>

        {visiblePeople.length ? (
          <div className="community-people-grid">
            {visiblePeople.map((person) => {
              const personInitial = (person.display_name || person.username || 'F').trim().charAt(0).toUpperCase()
              return (
                <article className="community-person-card" key={person.id}>
                  <div className="community-person-avatar">{personInitial}</div>
                  <strong>{person.display_name || 'Fameverse User'}</strong>
                  <small>{person.username ? `@${person.username}` : '@newuser'}</small>
                  <button
                    type="button"
                    className={`community-relation relation-${person.relation.key}`}
                    disabled={followNetwork.busyTargetId === person.id}
                    onClick={() => followNetwork.toggleFollow(person.id)}
                  >
                    {followNetwork.busyTargetId === person.id ? '…' : person.relation.label}
                  </button>
                </article>
              )
            })}
          </div>
        ) : (
          <div className="community-empty-circle">
            <span>◎</span>
            <strong>{query ? 'No matching people' : group === 'friends' ? 'No mutual friends yet' : `No ${group} yet`}</strong>
            <p>{query ? 'Try another name or username.' : 'Your real Fameverse connections will show here as your community grows.'}</p>
            <button type="button" onClick={() => setTab('discover')}>Explore live discovery</button>
          </div>
        )}
      </section>
    </section>
  )
}
