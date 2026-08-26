export default function LegalPage({ page, onBack }) {
  return (
    <section className="panel full-panel account-panel policy-panel">
      <button className="account-back" onClick={onBack}>← Settings</button>
      <span className="eyebrow">{page.eyebrow}</span>
      <h2>{page.title}</h2>
      <p className="policy-intro">{page.intro}</p>
      <div className="policy-sections">
        {page.sections.map(([title, copy]) => (
          <article key={title}>
            <strong>{title}</strong>
            <p>{copy}</p>
          </article>
        ))}
      </div>
      <div className="policy-beta-note">Beta draft · final legal review and production policies are required before a monetary or broad public launch.</div>
    </section>
  )
}
