import { useMemo, useState } from 'react'
import { getGifterBadgeForLevel, listGifterBadgeTiers } from '../../features/badges/gifterBadgeSystem.js'
import { getGifterProgress, gifterLevelRequirement } from '../../services/gifterLevels.js'
import GifterBadge from './GifterBadge.jsx'

const coinFormatter = new Intl.NumberFormat('en-US')

function tierRequirement(tier) {
  if (tier.minLevel === 1) return 1
  return gifterLevelRequirement(tier.minLevel)
}

export default function GifterProgressSection({ gifterStats }) {
  const [showHowItWorks, setShowHowItWorks] = useState(false)
  const totalCoinsSent = Math.max(0, Number(gifterStats?.totalCoinsSent || 0))
  const giftCount = Math.max(0, Number(gifterStats?.giftCount || 0))
  const progress = getGifterProgress(totalCoinsSent)
  const tiers = useMemo(() => listGifterBadgeTiers(), [])
  const currentTier = getGifterBadgeForLevel(progress.level)
  const hasEarnedFirstBadge = totalCoinsSent > 0
  const nextBadge = hasEarnedFirstBadge
    ? tiers.find((tier) => tier.minLevel > progress.level) || null
    : tiers[0]
  const nextBadgeRequirement = nextBadge ? tierRequirement(nextBadge) : null
  const coinsToNextBadge = nextBadgeRequirement === null
    ? 0
    : Math.max(0, nextBadgeRequirement - totalCoinsSent)
  const levelProgress = Math.round(progress.progress * 100)

  return (
    <section className="fv-gifter-profile-section" aria-label="Gifter progression">
      <div className="fv-gifter-profile-heading">
        <div>
          <span>GIFTER PROGRESSION</span>
          <h2>{currentTier.label}</h2>
          <p>Gift coins build your level. Levels unlock Fameverse gifter badges.</p>
        </div>
        <button type="button" onClick={() => setShowHowItWorks((value) => !value)}>
          {showHowItWorks ? 'Hide info' : 'How it works'}
        </button>
      </div>

      {showHowItWorks && (
        <div className="fv-gifter-how-it-works">
          Gifter progress is based only on gift coins sent. FameTaps do not increase gifter level. Unearned badge artwork stays locked until its requirement is reached.
        </div>
      )}

      <div className="fv-gifter-current-card">
        <div className={hasEarnedFirstBadge ? '' : 'is-locked'}>
          <GifterBadge level={progress.level} size="large" />
        </div>
        <div className="fv-gifter-current-copy">
          <span>Current level</span>
          <strong>Lv. {progress.level}</strong>
          {progress.isMaxLevel ? (
            <p>Max gifter level reached.</p>
          ) : (
            <>
              <div className="fv-gifter-progress-track" aria-label={`Level progress ${levelProgress}%`}>
                <span style={{ width: `${levelProgress}%` }} />
              </div>
              <p>
                {coinFormatter.format(totalCoinsSent)} / {coinFormatter.format(progress.nextRequirement)} coins · {coinFormatter.format(progress.coinsToNext)} coins to Lv. {progress.nextLevel}
              </p>
            </>
          )}
        </div>
      </div>

      <div className="fv-gifter-lifetime-stats">
        <div><strong>{coinFormatter.format(totalCoinsSent)}</strong><span>Total gift coins sent</span></div>
        <div><strong>{coinFormatter.format(giftCount)}</strong><span>Gifts sent</span></div>
      </div>

      <div className="fv-gifter-tier-strip" aria-label="Gifter badge tiers">
        {tiers.map((tier) => {
          const requirement = tierRequirement(tier)
          const earned = hasEarnedFirstBadge && progress.level >= tier.minLevel
          const current = earned && progress.level >= tier.minLevel && progress.level <= tier.maxLevel
          return (
            <article key={tier.id} className={`${earned ? 'is-earned' : 'is-locked'} ${current ? 'is-current' : ''}`}>
              <div className="fv-gifter-tier-badge"><GifterBadge level={tier.minLevel} size="small" showLevel={false} /></div>
              <strong>{tier.label}</strong>
              <span>Lv. {tier.minLevel}{tier.maxLevel > tier.minLevel ? `–${tier.maxLevel}` : ''}</span>
              <small>{earned ? 'Unlocked' : tier.minLevel === 1 ? 'Send your first gift' : `${coinFormatter.format(requirement)} coins to unlock`}</small>
            </article>
          )
        })}
      </div>

      <div className="fv-gifter-next-badge">
        <div>
          <span>NEXT BADGE</span>
          <strong>{nextBadge ? nextBadge.label : 'Fame Icon earned'}</strong>
        </div>
        <p>{nextBadge ? `${coinFormatter.format(coinsToNextBadge)} coins remaining` : 'You reached the top gifter badge.'}</p>
      </div>
    </section>
  )
}
