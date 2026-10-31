export default function GiftOverlay({ giftOverlay }) {
  if (!giftOverlay) return null

  const count = Math.max(1, Number(giftOverlay.count) || 1)
  const unitCost = Math.max(0, Number(giftOverlay.cost) || 0)
  const totalCoins = unitCost * count

  return (
    <div className="gift-overlay-simple" role="status" aria-live="polite">
      <span className="gift-overlay-emoji" aria-hidden="true">{giftOverlay.emoji || giftOverlay.activityEmoji || '✦'}</span>
      <div>
        <strong>{giftOverlay.sender}</strong>
        <small>sent {giftOverlay.label}{count > 1 ? ` ×${count}` : ''}</small>
        <small aria-label={`${totalCoins.toLocaleString()} coins`}>🟣 {totalCoins.toLocaleString()} coins</small>
      </div>
    </div>
  )
}
