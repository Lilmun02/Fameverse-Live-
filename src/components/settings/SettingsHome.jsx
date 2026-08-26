export default function SettingsHome({ session, openProfileMode, setSettingsDetail, setPolicyPage, signOut }) {
  return (
    <section className="panel full-panel account-panel settings-home">
      <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
      <span className="eyebrow">SETTINGS & SAFETY</span>
      <h2>Settings</h2>

      <div className="settings-section">
        <strong className="settings-section-title">Account</strong>
        <button className="settings-row" onClick={() => setSettingsDetail('account')}><span><b>Account details</b><small>{session.user.email}</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => openProfileMode('edit')}><span><b>Edit profile</b><small>Name, username and bio</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => setSettingsDetail('privacyControls')}><span><b>Privacy</b><small>Beta privacy controls and status</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => setSettingsDetail('notifications')}><span><b>Notifications</b><small>Live and creator alert status</small></span><i>›</i></button>
      </div>

      <div className="settings-section">
        <strong className="settings-section-title">Rules & legal</strong>
        <button className="settings-row" onClick={() => setPolicyPage('terms')}><span><b>Terms of Service</b><small>Platform and account rules</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => setPolicyPage('privacy')}><span><b>Privacy Policy</b><small>What the beta stores and uses</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => setPolicyPage('use')}><span><b>Terms of Use</b><small>Responsible platform use</small></span><i>›</i></button>
        <button className="settings-row" onClick={() => setPolicyPage('community')}><span><b>Community Guidelines</b><small>What Fameverse will and will not tolerate</small></span><i>›</i></button>
      </div>

      <div className="settings-section">
        <strong className="settings-section-title">Beta</strong>
        <div className="settings-info-card">
          <b>Current testing boundary</b>
          <p>Accounts and profiles use the Fameverse backend. Camera preview, comments and gifts are still test systems while realtime rooms, moderation and creator money systems are built.</p>
        </div>
      </div>

      <button className="signout-button" onClick={signOut}>Sign out</button>
    </section>
  )
}
