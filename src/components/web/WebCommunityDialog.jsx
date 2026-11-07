import { useEffect, useRef } from 'react'
import WebIcon from './WebIcon.jsx'

export default function WebCommunityDialog({ selected, onClose }) {
  const dialogRef = useRef(null)
  useEffect(() => {
    if (selected && dialogRef.current && !dialogRef.current.open) dialogRef.current.showModal()
  }, [selected])
  if (!selected) return null
  const creator = selected.live ? selected.item.host : selected.item
  return (
    <dialog className="fv-community-dialog" ref={dialogRef} onClose={onClose} aria-labelledby="fv-community-dialog-title">
      <form method="dialog"><button className="fv-community-dialog-close" type="submit" aria-label="Close creator details"><WebIcon name="close" /></button></form>
      <span className="fv-web-eyebrow">{selected.live ? 'LIVE ROOM DETAILS' : 'FAMEVERSE COMMUNITY'}</span>
      <h2 id="fv-community-dialog-title">{creator?.displayName || 'Fameverse creator'}</h2>
      {creator?.username && <span className="fv-community-dialog-handle">@{creator.username}</span>}
      {selected.live ? <><h3>{selected.item.title || 'Live conversation'}</h3><p>{selected.confirmed ? 'When these details were opened, this room appeared active. Its status may have changed since then.' : 'This is a previously loaded room. Its live status is not confirmed.'}</p><p>Live playback stays in the existing Fameverse app. This visual-only web preview does not start a viewer connection or change media and gift flows.</p></> : <><p>{creator?.bio || 'This community member has not provided a bio.'}</p>{Number.isFinite(Number(creator?.followerCount)) && <p>{Number(creator.followerCount).toLocaleString('en-US')} followers</p>}</>}
      <form method="dialog"><button className="fv-platform-signin" type="submit">Back to discovery</button></form>
    </dialog>
  )
}
