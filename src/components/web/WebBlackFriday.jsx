import '../../styles/web/black-friday.css'

const PREVIEW_OFFERS = [
  {
    coins: '10,000',
    discount: '50%',
    caption: 'Discount before applicable taxes',
    label: 'FIRST DROP',
    featured: false,
  },
  {
    coins: '50,000',
    discount: '60%',
    caption: 'Discount after taxes — pending checkout verification',
    label: 'BIG DROP',
    featured: false,
  },
  {
    coins: '100,000',
    discount: '80%',
    caption: 'Discount and tax calculation pending approval',
    label: 'ULTIMATE DROP',
    featured: true,
  },
]

function TickerPhrase() {
  return <span className="fv-bf-ticker-phrase">
    <span className="fv-bf-ticker-star" aria-hidden="true">✦</span>
    <strong>BLACK FRIDAY 2026</strong>
    <span>COMING NOVEMBER 27</span>
    <span>10K · 50K · 100K FAME COINS</span>
    <span>SALE NOT ACTIVE YET</span>
  </span>
}

export function WebBlackFridayBanner() {
  return (
    <div className="fv-bf-ticker" role="note" aria-label="Black Friday 2026 coin packs are coming November 27. The sale is not active yet.">
      <span className="fv-bf-ticker-badge">BLACK FRIDAY</span>
      <div className="fv-bf-ticker-window" aria-hidden="true">
        <div className="fv-bf-ticker-track"><TickerPhrase /><TickerPhrase /></div>
      </div>
      <span className="fv-bf-ticker-coming">COMING SOON</span>
    </div>
  )
}

export function WebBlackFridayPreview() {
  return (
    <section className="fv-bf-preview" id="black-friday-preview" aria-labelledby="fv-bf-heading">
      <div className="fv-bf-preview-heading">
        <div>
          <span className="fv-bf-kicker">LIMITED-TIME SALE · PREVIEW ONLY</span>
          <h2 id="fv-bf-heading">Black Friday <span>2026</span></h2>
          <p>Three Fame Coin drops. Every pack delivers the full amount of coins shown.</p>
        </div>
        <div className="fv-bf-date" aria-label="Sale planned for November 27, 2026">
          <span>NOV</span><strong>27</strong>
        </div>
      </div>
      <div className="fv-bf-offers">
        {PREVIEW_OFFERS.map((offer) => (
          <article className={offer.featured ? 'fv-bf-offer fv-bf-offer-featured' : 'fv-bf-offer'} key={offer.coins}>
            <span className="fv-bf-offer-label">{offer.label}</span>
            {offer.featured && <span className="fv-bf-popular">POPULAR</span>}
            <strong className="fv-bf-offer-coins">{offer.coins}</strong>
            <span className="fv-bf-offer-unit">FAME COINS</span>
            <div className="fv-bf-offer-discount"><strong>{offer.discount}</strong><span>OFF</span></div>
            <p>{offer.caption}</p>
            <span className="fv-bf-offer-status">FINAL PRICE COMING SOON</span>
          </article>
        ))}
      </div>
      <p className="fv-bf-preview-note">Not available to purchase yet. Final prices, applicable tax and any disclosed checkout fees must be confirmed before the sale starts.</p>
    </section>
  )
}
