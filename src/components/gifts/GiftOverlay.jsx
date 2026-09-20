function initialFor(value) {
  return String(value || 'F').trim().charAt(0).toUpperCase() || 'F'
}

export default function GiftOverlay({ giftOverlay }) {
  if (!giftOverlay) return null

  return (
    <div className="gift-overlay-simple fv-live-gift-toast" role="status" aria-live="polite">
      <span className="fv-live-gift-avatar" aria-hidden="true">{initialFor(giftOverlay.sender)}</span>
      <div className="fv-live-gift-copy">
        <strong>{giftOverlay.sender}</strong>
        <small>sent {giftOverlay.label}</small>
      </div>
      <span className="gift-overlay-emoji fv-live-gift-visual" aria-hidden="true">{giftOverlay.emoji || '✦'}</span>
      <strong className="fv-live-gift-count">×{giftOverlay.count || 1}</strong>
    </div>
  )
}
