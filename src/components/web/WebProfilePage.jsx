import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase.js'

export default function WebProfilePage({ profileId, ownUserId, onBack }) {
  const [profile, setProfile] = useState(null)
  const [followers, setFollowers] = useState(null)
  const [status, setStatus] = useState('loading')
  const isOwn = profileId === ownUserId

  useEffect(() => {
    let active = true
    setStatus('loading')
    setProfile(null)
    setFollowers(null)
    async function load() {
      try {
        const { data, error } = await supabase.from('profiles').select('id,username,display_name,bio,avatar_url,created_at').eq('id', profileId).maybeSingle()
        if (!active) return
        if (error || !data) { setStatus('error'); return }
        setProfile(data)
        const { count, error: countError } = await supabase.from('follows').select('following_id', { count: 'exact', head: true }).eq('following_id', profileId)
        if (!active) return
        if (!countError) setFollowers(count)
        setStatus('ready')
      } catch {
        if (active) setStatus('error')
      }
    }
    void load()
    return () => { active = false }
  }, [profileId])

  const name = profile?.display_name || profile?.username || 'Fameverse creator'
  return <main className="fv-profile-page">
    <div className="fv-profile-page-nav"><button type="button" onClick={onBack}>← Back to creators</button><span>FAMEVERSE PROFILE</span></div>
    {status === 'loading' && <p role="status">Loading profile…</p>}
    {status === 'error' && <section role="alert"><h1>Profile unavailable</h1><p>We could not load this profile. Please try again.</p><button type="button" onClick={onBack}>Back to creators</button></section>}
    {profile && <article className="fv-profile-page-main">
      <div className="fv-profile-page-banner" aria-hidden="true" />
      <div className="fv-profile-page-details">
        <div className="fv-profile-page-top"><div className="fv-profile-page-avatar"><span>{Array.from(name.trim())[0]?.toUpperCase() || 'F'}</span>{profile.avatar_url && <img src={profile.avatar_url} alt="" onError={(e) => { e.currentTarget.hidden = true }} />}</div><div className="fv-profile-page-account">{isOwn ? 'YOUR PROFILE' : 'CREATOR PROFILE'}</div></div>
        <h1>{name}</h1>
        {profile.username && <p className="fv-profile-page-handle">@{profile.username}</p>}
        <p className="fv-profile-page-bio">{profile.bio || 'No bio added yet.'}</p>
        <div className="fv-profile-page-metrics"><div><strong>{followers === null ? '—' : followers.toLocaleString('en-US')}</strong><span>Followers</span></div></div>
        {isOwn && <p className="fv-profile-page-own-note">This is your Fameverse profile. Profile editing is not yet available on the web; use the Fameverse app to update your details.</p>}
      </div>
    </article>}
  </main>
}
