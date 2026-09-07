import { useMemo, useState } from 'react'
import { gifts, MAX_BETA_GIFT_QUANTITY } from '../../config/gifts.js'
import GiftVisual, { primeGiftPosters } from './GiftVisual.jsx'

const CATEGORIES = [
  { id: 'all', label: 'All' },
  { id: 'classic', label: 'Classic' },
  { id: 'fameverse', label: 'Fameverse' },
]
const CUSTOM_PRESETS = [5, 10, 25, 50]

primeGiftPosters(gifts)

export default function LiveGiftTray({
  open,
  onClose,
  coins,
  sendGift,
  addTestCoins,
}) {
  const [category, setCategory] = useState('all')
  const [selectedGiftId, setSelectedGiftId] = useState(gifts[0]?.id || null)
  const [customOpen, setCustomOpen] = useState(false)
  const [customQuantity, setCustomQuantity] = useState(1)

  const selectedGift = gifts.find((gift) => gift.id === selectedGiftId) || gifts[0] || null
  const visibleGifts = useMemo(() => (
    category === 'all' ? gifts : gifts.filter((gift) => gift.category === category)
  ), [category])

  if (!open || !selectedGift) return null

  const normalizeQuantity = (value) => {
    const parsed = Number(value)
    if (!Number.isSafeInteger(parsed)) return 1
    return Math.min(MAX_BETA_GIFT_QUANTITY, Math.max(1, parsed))
  }

  const selectGift = (gift) => {
    setSelectedGiftId(gift.id)
    setCustomOpen(false)
    setCustomQuantity(1)
  }

  const sendOne = async () => {
    await sendGift(selectedGift, 1, { keepTrayOpen: true })
  }

  const sendCustom = async () => {
    const quantity = normalizeQuantity(customQuantity)
    const sent = await sendGift(selectedGift, quantity, { keepTrayOpen: true })
    if (sent) {
      setCustomOpen(false)
      setCustomQuantity(1)
    }
  }

  const totalCost = selectedGift.cost * normalizeQuantity(customQuantity)

  return (
    <div className="live-sheet-backdrop fv-gift-tray-backdrop" onClick={onClose}>
      <section className="live-sheet gift-test-sheet fv-gift-tray" onClick={(event) => event.stopPropagation()} aria-label="Send a gift">
        <div className="sheet-handle" />

        <header className="fv-gift-tray-head">
          <div>
            <span>GIFTS</span>
            <strong>Send a Gift</strong>
          </div>
          <div className="fv-gift-wallet">🪙 {coins.toLocaleString()}</div>
        </header>

        <nav className="fv-gift-categories" aria-label="Gift categories">
          {CATEGORIES.map((item) => (
            <button
              type="button"
              key={item.id}
              className={category === item.id ? 'is-active' : ''}
              onClick={() => setCategory(item.id)}
            >
              {item.label}
            </button>
          ))}
        </nav>

        <div className="fv-gift-grid" role="list">
          {visibleGifts.map((gift) => {
            const selected = gift.id === selectedGift.id
            return (
              <button
                type="button"
                key={gift.id}
                role="listitem"
                className={`fv-gift-card ${selected ? 'is-selected' : ''}`}
                aria-pressed={selected}
                onClick={() => selectGift(gift)}
              >
                <GiftVisual gift={gift} className={gift.poster ? 'fv-gift-card-poster' : 'fv-gift-card-symbol'} />
                <strong>{gift.label}</strong>
                <small>🪙 {gift.cost.toLocaleString()}</small>
              </button>
            )
          })}
        </div>

        <div className="fv-gift-selection-bar">
          <div className="fv-gift-selection-copy">
            <GiftVisual gift={selectedGift} className={selectedGift.poster ? 'fv-gift-selection-poster' : 'fv-gift-selection-symbol'} />
            <div>
              <small>Selected</small>
              <strong>{selectedGift.label}</strong>
            </div>
          </div>
          <button type="button" className="fv-gift-custom-open" onClick={() => setCustomOpen(true)}>
            Custom
          </button>
          <button type="button" className="fv-gift-send-primary" onClick={() => void sendOne()}>
            Send · 🪙 {selectedGift.cost.toLocaleString()}
          </button>
        </div>

        <div className="fv-gift-beta-row">
          <small>Beta tester balance</small>
          <button type="button" onClick={() => void addTestCoins(10000)}>+10K</button>
        </div>

        {customOpen && (
          <div className="fv-gift-custom-backdrop" onClick={() => setCustomOpen(false)}>
            <section className="fv-gift-custom-sheet" onClick={(event) => event.stopPropagation()} aria-label={`Custom amount for ${selectedGift.label}`}>
              <div className="sheet-handle" />
              <header>
                <div className="fv-gift-custom-title">
                  <GiftVisual gift={selectedGift} className={selectedGift.poster ? 'fv-gift-custom-poster' : 'fv-gift-custom-symbol'} />
                  <div>
                    <small>Send</small>
                    <strong>{selectedGift.label}</strong>
                  </div>
                </div>
                <button type="button" aria-label="Close custom amount" onClick={() => setCustomOpen(false)}>×</button>
              </header>

              <div className="fv-gift-quantity-stepper">
                <button type="button" onClick={() => setCustomQuantity((value) => normalizeQuantity(Number(value) - 1))}>−</button>
                <input
                  type="number"
                  inputMode="numeric"
                  min="1"
                  max={MAX_BETA_GIFT_QUANTITY}
                  value={customQuantity}
                  onChange={(event) => setCustomQuantity(normalizeQuantity(event.target.value))}
                  aria-label="Gift quantity"
                />
                <button type="button" onClick={() => setCustomQuantity((value) => normalizeQuantity(Number(value) + 1))}>+</button>
              </div>

              <div className="fv-gift-custom-presets">
                {CUSTOM_PRESETS.map((quantity) => (
                  <button type="button" key={quantity} onClick={() => setCustomQuantity(quantity)}>×{quantity}</button>
                ))}
              </div>

              <div className="fv-gift-custom-total">
                <span>Total cost</span>
                <strong>🪙 {totalCost.toLocaleString()}</strong>
              </div>

              <button type="button" className="fv-gift-custom-send" onClick={() => void sendCustom()}>
                Send ×{normalizeQuantity(customQuantity)}
              </button>
            </section>
          </div>
        )}
      </section>
    </div>
  )
}
