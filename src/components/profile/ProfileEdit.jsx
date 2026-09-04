import { useEffect, useRef, useState } from 'react'
import { validateProfileAvatar } from '../../services/profileAvatars.js'
import { cleanUsername } from '../../utils/profile.js'

export default function ProfileEdit({
  openProfileMode,
  profileDraft,
  setProfileDraft,
  saveProfile,
  profileBusy,
  profile,
  initial,
  displayName,
}) {
  const fileInputRef = useRef(null)
  const [avatarFile, setAvatarFile] = useState(null)
  const [avatarPreview, setAvatarPreview] = useState(profile?.avatar_url || null)
  const [avatarError, setAvatarError] = useState('')

  useEffect(() => {
    if (!avatarFile) {
      setAvatarPreview(profile?.avatar_url || null)
      return undefined
    }

    const objectUrl = URL.createObjectURL(avatarFile)
    setAvatarPreview(objectUrl)
    return () => URL.revokeObjectURL(objectUrl)
  }, [avatarFile, profile?.avatar_url])

  const handleAvatarChange = (event) => {
    const file = event.target.files?.[0] || null
    const validation = validateProfileAvatar(file)
    if (!validation.ok) {
      setAvatarFile(null)
      setAvatarError(validation.message)
      event.target.value = ''
      return
    }
    setAvatarError('')
    setAvatarFile(file)
  }

  const handleSubmit = async (event) => {
    const saved = await saveProfile(event, avatarFile)
    if (saved) openProfileMode('view')
  }

  return (
    <section className="panel full-panel account-panel fv-profile-edit-screen">
      <div className="fv-profile-edit-topbar">
        <button className="account-back" type="button" onClick={() => openProfileMode('view')}>← Profile</button>
        <strong>Edit Profile</strong>
        <span aria-hidden="true" />
      </div>

      <form className="profile-edit-form fv-profile-edit-form" onSubmit={handleSubmit}>
        <div className="fv-avatar-editor">
          <div className="fv-avatar-preview-wrap">
            {avatarPreview
              ? <img className="fv-avatar-preview" src={avatarPreview} alt={`${displayName} profile preview`} />
              : <div className="fv-avatar-preview fallback">{initial}</div>}
          </div>
          <input
            ref={fileInputRef}
            className="fv-avatar-file-input"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            onChange={handleAvatarChange}
          />
          <button type="button" className="fv-change-photo" onClick={() => fileInputRef.current?.click()} disabled={profileBusy}>
            {avatarFile ? 'Choose another photo' : 'Change photo'}
          </button>
          <small>JPG, PNG, or WEBP · up to 5 MB</small>
          {avatarError && <p className="fv-avatar-error" role="alert">{avatarError}</p>}
        </div>

        <label>
          Display name
          <input
            value={profileDraft.display_name}
            onChange={(event) => setProfileDraft({ ...profileDraft, display_name: event.target.value })}
            maxLength={40}
            autoComplete="name"
          />
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
              autoCapitalize="none"
              autoCorrect="off"
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
          <small className="fv-bio-count">{profileDraft.bio.length}/160</small>
        </label>

        <button className="auth-primary fv-save-profile" type="submit" disabled={profileBusy || Boolean(avatarError)}>
          {profileBusy ? 'Saving…' : 'Save profile'}
        </button>
      </form>
    </section>
  )
}
