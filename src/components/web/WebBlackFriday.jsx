import { useEffect, useState } from 'react'
import '../../styles/web/black-friday.css'

export const SALE_START_AT = Date.parse('2026-11-07T20:56:27.556Z')
export const SALE_END_AT = Date.parse('2026-12-07T20:56:27.556Z')

const PREVIEW_OFFERS = [
  {
    packId: 'stripe-bf2026-10000',
    coins: '10,000',
    discount: '25%',
    regularPrice: '$49.99',
    saleSubtotal: '$37.49',
    label: 'FIRST DROP',
    featured: false,
  },
  {
    packId: 'stripe-bf2026-50000',
    coins: '50,000',
    discount: '60%',
    regularPrice: '$499.99',
    saleSubtotal: '$200.00',
    label: 'BIG DROP',
    featured: false,
  },
  {
    packId: 'stripe-bf2026-100000',
    coins: '100,000',
    discount: '80%',
    regularPrice: '$899.99',
    saleSubtotal: '$180.00',
    label: 'ULTIMATE DROP',
    featured: true,
  },
]

function useSaleClock() {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    const ticker = window.setInterval(() => setNow(Date.now()), 1000)
    return () => window.clearInterval(ticker)
  }, [])
  const before = now < SALE_START_AT
  const ended = now >= SALE_END_AT
  return { before, ended, live: !before && !ended, left: Math.max(0, (before ? SALE_START_AT : SALE_END_AT) - now) }
}

function duration(left) {
  const seconds = Math.max(0, Math.floor(left / 1000))
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60
  return [days, hours, minutes, secs].map((item) => String(item).padStart(2, '0'))
}

function SaleTimer({ sale }) {
  const [days, hours, minutes, seconds] = duration(sale.left)
  return (
    <div className="fv-bf-clock" aria-label={sale.ended ? 'Black Friday sale ended' : 'Black Friday sale countdown'}>
      <span className="fv-bf-clock-caption">{sale.before ? 'STARTS IN' : sale.ended ? 'SALE FINISHED' : 'SALE ENDS IN'}</span>
      <div className="fv-bf-clock-units">
        {[[days, 'DAYS'], [hours, 'HRS'], [minutes, 'MIN'], [seconds, 'SEC']].map(([value, label]) => (
          <span className="fv-bf-clock-unit" key={label}><strong>{value}</strong><small>{label}</small></span>
        ))}
      </div>
      <small className="fv-bf-clock-date">Ends December 7, 2026 at 3:56 PM EST</small>
    </div>
  )
}

function TickerPhrase({ sale }) {
  return <span className="fv-bf-ticker-phrase">
    <span className="fv-bf-ticker-star" aria-hidden="true">✦</span>
    <strong>BLACK FRIDAY 2026</strong>
    <span>ONE MONTH · NOV 7–DEC 7</span>
    <span>10K · 50K · 100K FAME COINS</span>
    <span>{sale.ended ? 'SALE ENDED' : sale.before ? 'SALE STARTS SOON' : 'SALE LIVE NOW'}</span>
  </span>
}

export function WebBlackFridayBanner() {
  const sale = useSaleClock()
  return (
    <div className="fv-bf-ticker" role="note" aria-label="Fameverse Black Friday sale runs November 7 through December 7, 2026.">
      <span className="fv-bf-ticker-badge">BLACK FRIDAY</span>
      <div className="fv-bf-ticker-window" aria-hidden="true">
        <div className="fv-bf-ticker-track"><TickerPhrase sale={sale} /><TickerPhrase sale={sale} /></div>
      </div>
      <span className="fv-bf-ticker-coming">{sale.ended ? 'ENDED' : sale.before ? 'STARTING SOON' : 'LIVE NOW'}</span>
    </div>
  )
}

export function WebBlackFridayPreview({ salePacks = [], signedIn = false, isPreviewHost = false, checkoutEnabled = false, checkoutBusy = '', configBusy = false, onCheckout, onSignIn }) {
  const sale = useSaleClock()
  return (
    <section className="fv-bf-preview" id="black-friday-preview" aria-labelledby="fv-bf-heading">
      <div className="fv-bf-preview-heading">
        <div>
          <span className="fv-bf-kicker">ONE MONTH ONLY · NOVEMBER 7–DECEMBER 7, 2026</span>
          <h2 id="fv-bf-heading">Black Friday <span>2026</span></h2>
          <p>All three Black Friday packs are featured. Receive exactly the advertised Fame Coins. Discounted subtotals are shown before applicable tax.</p>
        </div>
        <SaleTimer sale={sale} />
      </div>
      <div className="fv-bf-offers">
        {PREVIEW_OFFERS.map((offer) => {
          const pack = salePacks.find((item) => item.id === offer.packId)
          const available = Boolean(pack) && checkoutEnabled && !configBusy && !checkoutBusy && sale.live
          return (
            <article className={offer.featured ? 'fv-bf-offer fv-bf-offer-featured' : 'fv-bf-offer'} key={offer.packId}>
              <span className="fv-bf-offer-label">{offer.label}</span>
              {offer.featured && <span className="fv-bf-popular">POPULAR</span>}
              <strong className="fv-bf-offer-coins">{offer.coins}</strong>
              <span className="fv-bf-offer-unit">FAME COINS</span>
              <div className="fv-bf-offer-discount"><strong>{offer.discount}</strong><span>OFF</span></div>
              <div className="fv-bf-pricing"><span className="fv-bf-original-price">{offer.regularPrice}</span><strong>{offer.saleSubtotal}</strong><small>Discounted subtotal · tax calculated separately when applicable</small></div>
              {sale.ended ? (
                <span className="fv-bf-offer-status">SALE ENDED</span>
              ) : isPreviewHost ? (
                <a className="fv-bf-buy" href="https://fameverse.app/coins#coin-packs">Buy on Fameverse</a>
              ) : (
                <button type="button" className="fv-bf-buy" disabled={signedIn && !available || sale.before} onClick={() => signedIn ? (pack && onCheckout?.(pack)) : onSignIn?.()}>
                  {checkoutBusy === offer.packId ? 'Opening Stripe…' : !signedIn ? 'Sign in to buy' : !available ? 'Checkout unavailable' : 'Buy with Stripe'}
                </button>
              )}
              <span className="fv-bf-offer-status">FULL {offer.coins} COINS AFTER PAYMENT VERIFICATION</span>
            </article>
          )
        })}
      </div>
      <div className="fv-bf-preview-foot">
        <p className="fv-bf-preview-note">Sale runs November 7–December 7, 2026, ending at 3:56 PM Eastern. The final amount due is shown in Stripe before you pay. No purchase changes the advertised number of coins.</p>
        <a className="fv-bf-shop-current" href="#coin-packs">See all coin packs</a>
      </div>
    </section>
  )
}
