import { listGifterBadgeTiers } from '../../features/badges/gifterBadgeSystem.js'
import { gifterLevelRequirement } from '../../services/gifterLevels.js'
import GifterBadge from './GifterBadge.jsx'

const numberFormatter = new Intl.NumberFormat('en-US')

export default function GifterBadgeGallery() {
  const tiers = listGifterBadgeTiers()

  return (
    <main className="fv-gifter-gallery">
      <header>
        <span>FAMEVERSE VISUAL QA</span>
        <h1>Gifter Badge Gallery</h1>
        <p>Profile-only badges. Live chat keeps the level chip only.</p>
      </header>

      <section className="fv-gifter-gallery-grid" aria-label="Approved gifter badge tiers">
        {tiers.map((tier) => (
          <article key={tier.id}>
            <GifterBadge level={tier.minLevel} size="large" />
            <div>
              <strong>Lv. {tier.minLevel}{tier.maxLevel > tier.minLevel ? `–${tier.maxLevel}` : ''}</strong>
              <small>{numberFormatter.format(gifterLevelRequirement(tier.minLevel))} gift coins to unlock this tier</small>
            </div>
          </article>
        ))}
      </section>

      <section className="fv-gifter-gallery-contexts">
        <article>
          <span>PROFILE PREVIEW</span>
          <div className="fv-gifter-gallery-profile">
            <div className="fv-gifter-gallery-avatar">F</div>
            <div>
              <strong>Fameverse User</strong>
              <small>@fameuser</small>
              <GifterBadge level={11} size="small" />
            </div>
          </div>
        </article>

        <article>
          <span>LIVE PREVIEW</span>
          <div className="fv-gifter-gallery-live-row">
            <div className="fv-gifter-gallery-avatar is-small">F</div>
            <div>
              <div><b className="fam-gifter-level">Lv. 11</b><strong> Fameverse User</strong></div>
              <p>Badge stays hidden here. Tap the user to open their profile.</p>
            </div>
          </div>
        </article>
      </section>
    </main>
  )
}
