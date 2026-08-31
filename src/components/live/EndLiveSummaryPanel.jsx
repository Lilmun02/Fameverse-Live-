function formatDuration(durationMs) {
  const totalSeconds = Math.max(0, Math.floor(durationMs / 1000))
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60)
    const remainingMinutes = minutes % 60
    return `${hours}h ${remainingMinutes}m`
  }
  return `${minutes}m ${seconds}s`
}

export default function EndLiveSummaryPanel({ summary, onDone }) {
  return (
    <section className="fv-live-summary" aria-labelledby="fv-live-summary-title">
      <header className="fv-live-summary-header">
        <span>LIVE ENDED</span>
        <h1 id="fv-live-summary-title">Session summary</h1>
        <p>{summary.title}</p>
      </header>

      <div className="fv-live-summary-stats">
        <div><strong>{formatDuration(summary.durationMs)}</strong><small>Duration</small></div>
        <div><strong>{summary.viewerCount}</strong><small>Viewers</small></div>
        <div><strong>{summary.giftCount}</strong><small>Gifts</small></div>
        <div><strong>{summary.totalGiftCoins.toLocaleString()}</strong><small>Gift coins</small></div>
      </div>

      <section className="fv-live-summary-money">
        <div>
          <span>Creator earnings</span>
          <strong>—</strong>
        </div>
        <p>Cash earnings are not calculated in beta because Fameverse has not configured its payout conversion yet.</p>
      </section>

      <section className="fv-live-summary-section">
        <div className="fv-live-summary-section-heading">
          <span>GIFTS RECEIVED</span>
          <small>{summary.giftBreakdown.length} types</small>
        </div>
        {summary.giftBreakdown.length ? (
          <div className="fv-live-summary-list">
            {summary.giftBreakdown.map((gift) => (
              <div key={gift.giftId} className="fv-live-summary-row">
                <span className="fv-live-summary-symbol">{gift.symbol}</span>
                <div><strong>{gift.label}</strong><small>×{gift.quantity}</small></div>
                <b>{gift.totalCoins.toLocaleString()} coins</b>
              </div>
            ))}
          </div>
        ) : (
          <p className="fv-live-summary-empty">No gifts were received during this session.</p>
        )}
      </section>

      <section className="fv-live-summary-section">
        <div className="fv-live-summary-section-heading">
          <span>GIFTERS</span>
          <small>{summary.gifters.length}</small>
        </div>
        {summary.gifters.length ? (
          <div className="fv-live-summary-list">
            {summary.gifters.map((gifter) => (
              <div key={gifter.sender} className="fv-live-summary-row gifter-row">
                <span className="fv-live-summary-symbol">🎁</span>
                <div><strong>{gifter.sender}</strong><small>{gifter.giftCount} gift{gifter.giftCount === 1 ? '' : 's'}</small></div>
                <b>{gifter.totalCoins.toLocaleString()} coins</b>
              </div>
            ))}
          </div>
        ) : (
          <p className="fv-live-summary-empty">No gifters this session.</p>
        )}
      </section>

      <button type="button" className="fv-live-summary-done" onClick={onDone}>Done</button>
    </section>
  )
}
