import { getGifterBadgeForLevel } from '../../features/badges/gifterBadgeSystem.js'

function BadgeArtwork({ tier }) {
  const showWings = ['platinum', 'diamond', 'royal', 'legendary', 'fame-icon'].includes(tier)
  const showCrown = ['silver', 'gold', 'platinum', 'royal', 'legendary', 'fame-icon'].includes(tier)
  const showJewel = ['diamond', 'royal', 'legendary', 'fame-icon'].includes(tier)
  const showOrbit = tier === 'fame-icon'
  const showStar = tier === 'spark'
  const showChevron = tier === 'bronze'

  return (
    <svg
      className={`fv-gifter-badge-svg is-${tier}`}
      data-gifter-artwork={tier}
      viewBox="0 0 48 48"
      aria-hidden="true"
      focusable="false"
    >
      {showWings && (
        <g className="fv-gifter-wings">
          <path d="M10 17 2 13l3 9-4 4 9 2 5-5-5-6Z" />
          <path d="m38 17 8-4-3 9 4 4-9 2-5-5 5-6Z" />
        </g>
      )}

      <path className="fv-gifter-shield" d="M24 2 41 8v13c0 11-7.4 19-17 24C14.4 40 7 32 7 21V8L24 2Z" />
      <path className="fv-gifter-shield-inner" d="M24 7 36 11v10c0 7.8-4.8 13.7-12 17.6C16.8 34.7 12 28.8 12 21V11L24 7Z" />

      {showStar && <path className="fv-gifter-core" d="m24 11 3.1 6.3 7 .9-5.1 4.9 1.3 6.9-6.3-3.3-6.3 3.3 1.3-6.9-5.1-4.9 7-.9L24 11Z" />}
      {showChevron && <path className="fv-gifter-core" d="m15 17 9 7 9-7-3 13H18l-3-13Zm4 15h10v3H19v-3Z" />}

      {showCrown && (
        <g className="fv-gifter-crown">
          <path d="m14 27 2-12 6 5 3-8 5 8 6-5-2 12H14Z" />
          <path d="M16 30h16v4H16z" />
        </g>
      )}

      {showJewel && <path className="fv-gifter-jewel" d="m24 16 5 5-5 6-5-6 5-5Z" />}

      {tier === 'gold' && (
        <g className="fv-gifter-laurel">
          <path d="M13 30c-4-3-6-7-6-12 4 2 7 6 8 10" />
          <path d="M35 30c4-3 6-7 6-12-4 2-7 6-8 10" />
        </g>
      )}

      {tier === 'legendary' && (
        <g className="fv-gifter-rays">
          <path d="M24 1v5M6 9l4 3M42 9l-4 3M2 25h5M46 25h-5" />
        </g>
      )}

      {showOrbit && (
        <g className="fv-gifter-orbit">
          <ellipse cx="24" cy="24" rx="22" ry="9" />
          <circle cx="43" cy="21" r="2" />
        </g>
      )}
    </svg>
  )
}

export default function GifterBadge({ level = 1, size = 'medium', showLevel = true }) {
  const normalizedLevel = Math.min(99, Math.max(1, Math.floor(Number(level) || 1)))
  const badge = getGifterBadgeForLevel(normalizedLevel)

  return (
    <span
      className={`fv-gifter-badge fv-gifter-badge-${size}`}
      data-gifter-tier={badge.id}
      aria-label={`${badge.label}, level ${normalizedLevel}`}
    >
      <span className="fv-gifter-badge-mark" aria-hidden="true">
        <BadgeArtwork tier={badge.id} />
      </span>
      <span className="fv-gifter-badge-copy">
        <strong>{badge.label}</strong>
        {showLevel && <small>Lv. {normalizedLevel}</small>}
      </span>
    </span>
  )
}
