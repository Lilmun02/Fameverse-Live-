import { useState } from 'react'
import { gifts } from '../../config/gifts.js'
import { seekGiftThumbnail } from '../../utils/media.js'

const QUICK_GIFT_AMOUNTS = [1, 5, 10]

export default function LiveGiftTray({
  open,
  onClose,
  coins,
  sendGift,
  addTestCoins,
}) {
  const [customGiftId, setCustomGiftId] = useState(null)
  const [giftAmounts, setGiftAmounts] = useState({})

  if (!open) return null

  const giftAmountValue = (giftId) => giftAmounts[giftId] ?? '1'

  const updateGiftAmount = (giftId, value) => {
    setGiftAmounts((amounts) => ({ ...amounts, [giftId]: value }))
  }

  const sendQuickGift = (gift, quantity) => {
    sendGift(gift, quantity, { keepTrayOpen: true })
  }

  const sendCustomGift = (gift) => {
    const sent = sendGift(gift, Number(giftAmountValue(gift.id)))
    if (sent) setCustomGiftId(null)
  }

  return (
    <div className="live-sheet-backdrop" onClick={onClose}>
      <div className="live-sheet gift-test-sheet" onClick={(event) => event.stopPropagation()}>
        <div className="sheet-handle" />
        <div className="sheet-heading">
          <div><span>GIFTS · BETA TEST</span><strong>Send gifts</strong></div>
          <div className="test-balance">🪙 {coins.toLocaleString()}</div>
        </div>
        <p>Tap 1×, 5×, or 10× to send that amount while keeping the gift tray open. Custom amount is still available.</p>
        <div className="live-gift-grid">
          {gifts.map((gift) => {
            const customOpen = customGiftId === gift.id
            const amountValue = giftAmountValue(gift.id)
            return (
              <div
                className={`live-gift-item ${gift.cinematic ? 'live-gift-item-cinematic' : ''} ${customOpen ? 'is-custom-open' : ''}`}
                key={gift.id}
              >
                {gift.video ? (
                  <video
                    className="live-gift-thumbnail"
                    src={`${gift.video}#t=${gift.thumbnailTime || 0}`}
                    muted
                    playsInline
                    preload="metadata"
                    onLoadedMetadata={(event) => seekGiftThumbnail(event, gift.thumbnailTime)}
                  />
                ) : (
                  <span>{gift.emoji}</span>
                )}
                <strong>{gift.label}</strong>
                <small>{gift.cost} {gift.cost === 1 ? 'coin' : 'coins'} each</small>
                <div className="gift-quick-amounts" aria-label={`${gift.label} quick amounts`}>
                  {QUICK_GIFT_AMOUNTS.map((quantity) => (
                    <button
                      type="button"
                      key={quantity}
                      onClick={() => sendQuickGift(gift, quantity)}
                    >
                      {quantity}×
                    </button>
                  ))}
                </div>
                <button
                  type="button"
                  className="gift-amount-toggle"
                  onClick={() => setCustomGiftId(customOpen ? null : gift.id)}
                >
                  Custom amount
                </button>
                {customOpen && (
                  <div className="gift-custom-row">
                    <input
                      type="number"
                      inputMode="numeric"
                      min="1"
                      step="1"
                      value={amountValue}
                      aria-label={`Custom amount for ${gift.label}`}
                      onChange={(event) => updateGiftAmount(gift.id, event.target.value)}
                    />
                    <button type="button" onClick={() => sendCustomGift(gift)}>
                      Send ×{amountValue || '0'}
                    </button>
                  </div>
                )}
              </div>
            )
          })}
        </div>
        <div className="test-wallet-row">
          <small>Beta tester balance</small>
          <button onClick={() => addTestCoins(10000)}>+10K test coins</button>
        </div>
      </div>
    </div>
  )
}
