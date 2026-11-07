import { useEffect, useRef } from 'react'
import WebIcon from './WebIcon.jsx'

export default function WebCommunityDialog({ selected, onClose }) {
  const dialogRef = useRef(null)

  useEffect(() => {
    if (selected && dialogRef.current && !dialogRef.current.open) dialogRef.current.showModal()
  }, [selected])

  if (!selected) return null

  const creator = selected.live ? selected.item.host : selected.item
  const name = creator?.displayName || 'Fameverse creator'
  const initial = Array.from(name.trim())[0]?.toUpperCase() || 'F'
  const followers = Number(creator?.followerCount)

  return (
    <dialog className="fv-community-dialog fv-creator-profile" ref={dialogRef} onClose={onClose} aria-labelledby="fv-community-dialog-title">
      <div className="fv-creator-profile-cover" aria-hidden="true"><span>FAMEVERSE</span></div>
      <form method="dialog" className="fv-creator-profile-close">
        <button className="fv-community-dialog-close" type="submit" aria-label="Close profile"><WebIcon name="close" /></button>
      </form>
      <div className="fv-creator-profile-body">
        <div className="fv-creator-profile-identity">
          <div className="fv-creator-profile-avatar">
            <span>{initial}</span>
            {creator?.avatarUrl && <img src={creator.avatarUrl} alt="" onError={(event) => { event.currentTarget.hidden = true }} />}
          </div>
          <div className="fv-creator-profile-names">
            <span className="fv-web-eyebrow">FAMEVERSE PROFILE</span>
            <h2 id="fv-community-dialog-title">{name}</h2>
            {creator?.username && <span className="fv-community-dialog-handle">@{creator.username}</span>}
          </div>
        </div>
        {!selected.live && <div className="fv-creator-profile-stats" aria-label="Creator statistics">
          <div><strong>{Number.isFinite(followers) ? followers.toLocaleString('en-US') : '—'}</strong><span>Followers</span></div>
        </div>}
        <section className="fv-creator-profile-about" aria-label="About this creator">
          <h3>{selected.live ? selected.item.title || 'Live conversation' : 'About'}</h3>
          {selected.live
            ? <><p>{selected.confirmed ? 'This room appeared active when opened. Its status may have changed.' : 'Live status is not confirmed.'}</p><p>Watch live streams in the Fameverse app.</p></>
            : <p>{creator?.bio || 'This creator has not added a bio yet.'}</p>}
        </section>
        <div className="fv-creator-profile-footer"><span>Fameverse creator community</span><form method="dialog"><button type="submit">Close profile</button></form></div>
      </div>
    </dialog>
  )
}
