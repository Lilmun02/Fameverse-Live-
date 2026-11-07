import WebIcon from './WebIcon.jsx'

export default function WebHero() {
  return (
    <section className="fv-web-hero fv-platform-hero">
      <div className="fv-platform-hero-art" aria-hidden="true" />
      <div className="fv-platform-hero-copy"><div className="fv-web-eyebrow">YOUR COMMUNITY. IN REAL TIME.</div>
        <h1>Make every moment <span>count.</span></h1>
        <p>Find your people. Follow your favorite creators. Be part of the moments that matter.</p>
        <div className="fv-platform-hero-actions"><a className="fv-web-primary-link" href="#discover-creators">Explore creators<WebIcon name="arrow" size={18} /></a><a className="fv-platform-secondary-link" href="#coin-packs">Support a creator</a></div>
        <span className="fv-platform-hero-footnote">One Fameverse account. A world of connection.</span>
      </div>
    </section>
  )
}
