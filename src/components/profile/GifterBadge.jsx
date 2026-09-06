import { getGifterBadgeForLevel } from '../../features/badges/gifterBadgeSystem.js'

export default function GifterBadge({ level = 1, size = 'medium', showLevel = true }) {
  const normalizedLevel = Math.min(99, Math.max(1, Math.floor(Number(level) || 1)))
  const badge = getGifterBadgeForLevel(normalizedLevel)

  return (
    <span
      className={`fv-gifter-badge fv-gifter-badge-${size}`}
      data-gifter-tier={badge.id}
      aria-label={`${badge.label}, level ${normalizedLevel}`}
    >
      <span className="fv-gifter-badge-mark" aria-hidden="true">{badge.icon}</span>
      <span className="fv-gifter-badge-copy">
        <strong>{badge.label}</strong>
        {showLevel && <small>Lv. {normalizedLevel}</small>}
      </span>
    </span>
  )
}
