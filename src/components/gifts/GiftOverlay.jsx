export default function GiftOverlay({ giftOverlay }) {
  if (!giftOverlay) return null

  return (
    <div className="gift-overlay-simple" role="status" aria-live="polite">
      <span className="gift-overlay-emoji">{giftOverlay.emoji}</span>
      <div>
        <strong>{giftOverlay.sender}</strong>
        <small>sent {giftOverlay.label}{giftOverlay.count > 1 ? ` ×${giftOverlay.count}` : ''}</small>
      </div>
    </div>
  )
}
