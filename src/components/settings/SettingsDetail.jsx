const contentByType = {
  account: {
    eyebrow: 'ACCOUNT',
    title: 'Account details',
    body: 'Your Fameverse beta account is active and connected to the Fameverse backend.',
    rows: (email) => [['Email', email], ['Account status', 'Active beta account'], ['Password & security', 'Security controls expand before public testing']],
  },
  privacyControls: {
    eyebrow: 'PRIVACY',
    title: 'Privacy controls',
    body: 'These controls are intentionally limited during the private beta. The production privacy center will add audience, discoverability, blocking, and data controls.',
    rows: () => [['Profile visibility', 'Private beta default'], ['Live visibility', 'Local preview only'], ['Direct messages', 'Not enabled']],
  },
  notifications: {
    eyebrow: 'NOTIFICATIONS',
    title: 'Notifications',
    body: 'Push notifications are not enabled in this beta yet. We will add granular creator, live, follow, gift, and safety notification controls.',
    rows: () => [['Live alerts', 'Coming soon'], ['Creator activity', 'Coming soon'], ['Safety notices', 'Coming soon']],
  },
}

export default function SettingsDetail({ type, email, onBack }) {
  const content = contentByType[type]
  if (!content) return null

  return (
    <section className="panel full-panel account-panel">
      <button className="account-back" onClick={onBack}>← Settings</button>
      <span className="eyebrow">{content.eyebrow}</span>
      <h2>{content.title}</h2>
      <p className="settings-detail-copy">{content.body}</p>
      <div className="settings-list">
        {content.rows(email).map(([label, value]) => (
          <div key={label}><span>{label}</span><strong>{value}</strong></div>
        ))}
      </div>
    </section>
  )
}
