import '../../styles/web/black-friday.css'

const PREVIEW_OFFERS = [
  {
    coins: '10,000',
    discount: '25%',
    regularPrice: '$49.99',
    saleSubtotal: '$37.49',
    caption: '25% off the subtotal; applicable tax calculated at checkout',
    label: 'FIRST DROP',
    featured: false,
  },
  {
    coins: '50,000',
    discount: '60%',
    regularPrice: '$499.99',
    saleSubtotal: '$200.00',
    caption: '60% discount estimate; final tax sequence verified at checkout',
    label: 'BIG DROP',
    featured: false,
  },
  {
    coins: '100,000',
    discount: '80%',
    regularPrice: '$899.99',
    saleSubtotal: '$180.00',
    caption: '80% discount estimate; applicable tax calculated at checkout',
    label: 'ULTIMATE DROP',
    featured: true,
  },
]

function TickerPhrase() {
  return <span className="fv-bf-ticker-phrase">
    <span className="fv-bf-ticker-star" aria-hidden="true">✦</span>
    <strong>BLACK FRIDAY 2026</strong>
    <span>NOV 27–30 · WEEKEND SALE PREVIEW</span>
    <span>10K · 50K · 100K FAME COINS</span>
    <span>SALE NOT ACTIVE YET</span>
  </span>
}

export function WebBlackFridayBanner() {
  return (
    <div className="fv-bf-ticker" role="note" aria-label="Black Friday 2026 sale weekend is proposed for November 27 through November 30, pending owner approval. The sale is not active yet.">
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
          <span className="fv-bf-kicker">NOV 27–30 PROPOSED · BLACK FRIDAY WEEKEND PREVIEW</span>
          <h2 id="fv-bf-heading">Black Friday <span>2026</span></h2>
          <p>All three Black Friday packs featured. Full advertised coin amounts included. Final sale closing time subject to owner approval.</p>
        </div>
        <div className="fv-bf-date" aria-label="Sale proposed to begin November 27, 2026; closing date subject to owner approval">
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
            <div className="fv-bf-pricing"><span className="fv-bf-original-price">{offer.regularPrice}</span><strong>{offer.saleSubtotal}</strong><small>Estimated discounted subtotal</small></div>
            <p>{offer.caption}</p>
            <span className="fv-bf-offer-status">BLACK FRIDAY CHECKOUT OPENS AFTER VERIFICATION</span>
          </article>
        ))}
      </div>
      <div className="fv-bf-preview-foot"><p className="fv-bf-preview-note">Sale packs are not active. The amounts shown are discounted subtotals; tax and any disclosed checkout fees appear before payment. Purchases will only be enabled after checkout and coin delivery are verified.</p><a className="fv-bf-shop-current" href="#coin-packs">View available Fame Coin packs</a></div>
    </section>
  )
}
