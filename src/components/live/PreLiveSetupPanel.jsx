import { gifts } from '../../config/gifts.js'
import { primeGiftAudio } from '../../features/gifts/renderer/gift-audio.js'

export default function PreLiveSetupPanel({
  displayName,
  username,
  initial,
  draft,
  updateField,
  toggleWishlistGift,
  beginLive,
  isStartingLive,
}) {
  const titleReady = Boolean(draft.title.trim())

  const startLiveWithAudioReady = () => {
    primeGiftAudio()
    beginLive()
  }

  return (
    <section className="fv-live-setup" aria-labelledby="fv-live-setup-title">
      <header className="fv-live-setup-header">
        <div>
          <span>LIVE</span>
          <h1 id="fv-live-setup-title">Set up your live</h1>
          <p>Give people a reason to join before the room opens.</p>
        </div>
        <div className="fv-live-setup-avatar" aria-label={displayName}>{initial}</div>
      </header>

      <div className="fv-live-setup-creator">
        <strong>{displayName}</strong>
        <small>{username}</small>
      </div>

      <div className="fv-live-setup-fields">
        <label>
          <span>Live title <b>Required</b></span>
          <input
            type="text"
            maxLength={80}
            value={draft.title}
            onChange={(event) => updateField('title', event.target.value)}
            placeholder="What is this live about?"
          />
          <small>{draft.title.length}/80</small>
        </label>

        <label>
          <span>Live goal <b>Optional</b></span>
          <input
            type="text"
            maxLength={60}
            value={draft.goal}
            onChange={(event) => updateField('goal', event.target.value)}
            placeholder="Example: 1,000 likes or 20 gifts"
          />
          <small>{draft.goal.length}/60</small>
        </label>

        <div className="fv-wishlist-field">
          <div className="fv-wishlist-heading">
            <span>Wishlist gifts</span>
            <b>Optional · {draft.wishlistGiftIds.length} selected</b>
          </div>
          <p>Pick only gifts that actually exist in Fameverse.</p>
          <div className="fv-wishlist-grid" role="group" aria-label="Wishlist gifts">
            {gifts.map((gift) => {
              const selected = draft.wishlistGiftIds.includes(gift.id)
              const symbol = gift.activityEmoji || gift.emoji || '✦'
              return (
                <button
                  key={gift.id}
                  type="button"
                  className={selected ? 'selected' : ''}
                  aria-pressed={selected}
                  onClick={() => toggleWishlistGift(gift.id)}
                >
                  <span className="fv-wishlist-symbol">{symbol}</span>
                  <span className="fv-wishlist-copy">
                    <strong>{gift.label}</strong>
                    <small>{gift.cost.toLocaleString()} coin{gift.cost === 1 ? '' : 's'}</small>
                  </span>
                  <span className="fv-wishlist-check" aria-hidden="true">{selected ? '✓' : '+'}</span>
                </button>
              )
            })}
          </div>
        </div>
      </div>

      <div className="fv-live-setup-foot">
        <p>Camera and microphone permission is requested only after you tap Go Live.</p>
        <button
          type="button"
          className="fv-live-setup-go"
          disabled={!titleReady || isStartingLive}
          onClick={startLiveWithAudioReady}
        >
          {isStartingLive ? 'Starting…' : 'Go Live'}
        </button>
      </div>
    </section>
  )
}
