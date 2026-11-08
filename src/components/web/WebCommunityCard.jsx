import WebIcon from './WebIcon.jsx'

export default function WebCommunityCard({ item, live, confirmed, onSelect }) {
  const creator = live ? item.host : item
  const name = creator?.displayName || 'Fameverse member'
  const initial = Array.from(name.trim())[0]?.toUpperCase() || 'F'
  return (
    <button className="fv-community-card" type="button" onClick={onSelect} aria-label={`${live ? 'View live room details' : 'View creator details'}: ${name}`}>
      <div className="fv-community-card-cover"><span className="fv-community-card-monogram">{initial}</span>{creator?.avatarUrl && <img key={creator.avatarUrl} src={creator.avatarUrl} alt="" loading="lazy" onError={(event) => { event.currentTarget.hidden = true }} />}
        {live && <span className={confirmed ? 'fv-community-live' : 'fv-community-live is-unconfirmed'}>{confirmed ? 'LIVE IN APP' : 'LAST KNOWN LIVE'}</span>}
        {!live && <span className="fv-community-profile-label">MEMBER PROFILE</span>}
      </div>
      <div className="fv-community-card-info"><strong>{name}</strong>{creator?.username && <span>@{creator.username}</span>}<p>{live ? item.title || 'Live conversation' : creator?.bio || 'Meet this member of the Fameverse community.'}</p><div><small>{live && Number.isFinite(Number(item.fameTaps)) ? `${Number(item.fameTaps).toLocaleString('en-US')} Fame taps` : !live && Number.isFinite(Number(creator?.followerCount)) ? `${Number(creator.followerCount).toLocaleString('en-US')} followers` : 'Fameverse community'}</small><WebIcon name="arrow" size={17} /></div></div>
    </button>
  )
}
