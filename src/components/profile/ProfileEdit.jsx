import { cleanUsername } from '../../utils/profile.js'

export default function ProfileEdit({ openProfileMode, profileDraft, setProfileDraft, saveProfile, profileBusy }) {
  const handleSubmit = async (event) => {
    const saved = await saveProfile(event)
    if (saved) openProfileMode('view')
  }

  return (
    <section className="panel full-panel account-panel">
      <button className="account-back" onClick={() => openProfileMode('view')}>← Profile</button>
      <span className="eyebrow">EDIT PROFILE</span>
      <h2>Make it yours</h2>
      <form className="profile-edit-form" onSubmit={handleSubmit}>
        <label>
          Display name
          <input value={profileDraft.display_name} onChange={(event) => setProfileDraft({ ...profileDraft, display_name: event.target.value })} maxLength={40} />
        </label>
        <label>
          Username
          <div className="username-field">
            <span>@</span>
            <input
              value={profileDraft.username}
              onChange={(event) => setProfileDraft({ ...profileDraft, username: cleanUsername(event.target.value) })}
              maxLength={24}
              placeholder="username"
            />
          </div>
        </label>
        <label>
          Bio
          <textarea
            value={profileDraft.bio}
            onChange={(event) => setProfileDraft({ ...profileDraft, bio: event.target.value })}
            maxLength={160}
            rows={4}
            placeholder="Tell people about you"
          />
        </label>
        <button className="auth-primary" type="submit" disabled={profileBusy}>{profileBusy ? 'Saving…' : 'Save profile'}</button>
      </form>
    </section>
  )
}
