import { useMemo, useState } from 'react'

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

  const groups = { friends, following: followNetwork.following, followers: followNetwork.followers }
  const visiblePeople = useMemo(() => {
    const needle = query.trim().toLowerCase()
    if (!needle) return groups[group]
    return groups[group].filter((person) => (
      person.display_name?.toLowerCase().includes(needle)
      || person.username?.toLowerCase().includes(needle)
    ))
  }, [friends, followNetwork.followers, followNetwork.following, group, query])

  return (
    <section className="fv-home" aria-labelledby="fv-home-title">
      <header className="fv-home-topbar">
        <button type="button" className="fv-wordmark" onClick={() => setTab('home')} aria-label="Fameverse home">FAMEVERSE</button>
        <div className="fv-home-actions">
          {!standalone && <button type="button" className="fv-install" onClick={installPwa}>Install</button>}
          <button type="button" className="fv-avatar-button" onClick={() => setTab('profile')} aria-label="Open profile">{initial}</button>
        </div>
      </header>

      <div className="fv-home-intro">
        <span>COMMUNITY</span>
        <h1 id="fv-home-title">Hey, {displayName}</h1>
        <p>{username} · Your connections live here.</p>
      </div>

      <label className="fv-search">
        <span aria-hidden="true">⌕</span>
        <input type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search creators" aria-label="Search your community" />
      </label>

      <div className="fv-community-tabs" role="tablist" aria-label="Community connections">
        {GROUPS.map(([key, label]) => {
          const count = key === 'friends' ? friends.length : key === 'following' ? followNetwork.followingCount : followNetwork.followerCount
          return (
            <button type="button" role="tab" aria-selected={group === key} className={group === key ? 'active' : ''} key={key} onClick={() => setGroup(key)}>
              <span>{label}</span><small>{count}</small>
            </button>
          )
        })}
      </div>

      <section className="fv-home-section">
        <div className="fv-section-heading">
          <div><span>{GROUPS.find(([key]) => key === group)?.[1] || 'Community'}</span><h2>Your circle</h2></div>
        </div>

        {visiblePeople.length ? (
          <div className="fv-people-grid">
            {visiblePeople.map((person) => {
              const personInitial = (person.display_name || person.username || 'F').trim().charAt(0).toUpperCase()
              return (
                <article className="fv-person-card" key={person.id}>
                  <div className="fv-person-avatar">{personInitial}</div>
                  <div className="fv-person-copy"><strong>{person.display_name || 'Fameverse User'}</strong><small>{person.username ? `@${person.username}` : '@newuser'}</small></div>
                  <button type="button" className={`fv-relation relation-${person.relation.key}`} disabled={followNetwork.busyTargetId === person.id} onClick={() => followNetwork.toggleFollow(person.id)}>
                    {followNetwork.busyTargetId === person.id ? '…' : person.relation.label}
                  </button>
                </article>
              )
            })}
          </div>
        ) : (
          <div className="fv-empty-inline">
            <div><strong>{query ? 'No matches' : group === 'friends' ? 'Your circle is empty for now' : `No ${group} yet`}</strong><p>{query ? 'Try another name or username.' : 'When you connect with real people, they will show up here.'}</p></div>
          </div>
        )}
      </section>
    </section>
  )
}
