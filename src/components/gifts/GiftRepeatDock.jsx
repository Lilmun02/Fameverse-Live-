import { seekGiftThumbnail } from '../../utils/media.js'

export default function GiftRepeatDock({ isLive, premiumRepeat, sendGift }) {
  if (!isLive || !premiumRepeat) return null

  return (
    <div className="gift-repeat-dock" role="group" aria-label={`Repeat ${premiumRepeat.label}`}>
      <video
        className="gift-repeat-thumb"
        src={`${premiumRepeat.video}#t=${premiumRepeat.thumbnailTime || 0}`}
        muted
        playsInline
        preload="metadata"
        onLoadedMetadata={(event) => seekGiftThumbnail(event, premiumRepeat.thumbnailTime)}
      />
      <div className="gift-repeat-copy">
        <strong>{premiumRepeat.label}</strong>
        <small>{premiumRepeat.cost} coins · combo ×{premiumRepeat.comboCount}</small>
      </div>
      <button type="button" onClick={() => sendGift(premiumRepeat)}>Send again</button>
    </div>
  )
}
