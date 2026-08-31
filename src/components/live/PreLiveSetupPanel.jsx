export default function PreLiveSetupPanel({
  displayName,
  username,
  initial,
  draft,
  updateField,
  beginLive,
  isStartingLive,
}) {
  const titleReady = Boolean(draft.title.trim())

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

        <label>
          <span>Wishlist <b>Optional</b></span>
          <textarea
            maxLength={120}
            rows={3}
            value={draft.wishlist}
            onChange={(event) => updateField('wishlist', event.target.value)}
            placeholder="Add something you are wishing for during this live"
          />
          <small>{draft.wishlist.length}/120</small>
        </label>
      </div>

      <div className="fv-live-setup-foot">
        <p>Camera and microphone permission is requested only after you tap Go Live.</p>
        <button
          type="button"
          className="fv-live-setup-go"
          disabled={!titleReady || isStartingLive}
          onClick={beginLive}
        >
          {isStartingLive ? 'Starting…' : 'Go Live'}
        </button>
      </div>
    </section>
  )
}
