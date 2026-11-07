const sections = [
  { id: 'announcements', eyebrow: 'OFFICIAL NEWS', title: 'Announcements', description: 'Official Fameverse news will be published here. Check back for confirmed notices.', items: [{ title: 'Official announcements', text: 'No new announcement has been published yet.', status: 'Awaiting announcement' }] },
  { id: 'features', eyebrow: 'THE APP', title: 'Features & benefits', description: 'Fameverse Live is built around creators, live community and supporter experiences.', items: [{ title: 'Creator community', text: 'Discover profiles and connect with creators.' }, { title: 'Live experiences', text: 'Live streaming belongs in the native Fameverse app, not on this website.' }, { title: 'Fame Coins & Fame Rubies', text: 'Fame Coins are for gifting. Fame Rubies represent eligible creator earnings. Both balances belong to every account; Ruby balances may be zero.' }] },
  { id: 'updates', eyebrow: 'WHAT IS NEXT', title: 'Upcoming updates', description: 'Release details will appear here after they are confirmed.', items: [{ title: 'Release notes', text: 'No upcoming release date has been officially announced here.', status: 'Date to be announced' }] },
  { id: 'events', eyebrow: 'COMMUNITY CALENDAR', title: 'Future events', description: 'Watch this space for Fameverse community events and schedules.', items: [{ title: 'Upcoming events', text: 'There are no confirmed event dates to display yet.', status: 'To be announced' }] },
]

export default function WebNewsHub() {
  return <div className="fv-news-hub">
    <nav className="fv-news-nav" aria-label="Fameverse information"><a href="#announcements">Announcements</a><a href="#features">Features</a><a href="#updates">Updates</a><a href="#events">Events</a></nav>
    {sections.map((section) => <section className="fv-news-section" id={section.id} key={section.id}>
      <div className="fv-news-section-head"><span className="fv-web-eyebrow">{section.eyebrow}</span><h2>{section.title}</h2><p>{section.description}</p></div>
      <div className="fv-news-grid">{section.items.map((item) => <article className="fv-news-item" key={item.title}><h3>{item.title}</h3><p>{item.text}</p>{item.status && <small>{item.status}</small>}</article>)}</div>
    </section>)}
  </div>
}
