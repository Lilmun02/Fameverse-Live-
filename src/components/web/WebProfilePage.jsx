import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../services/supabase.js'

export default function WebProfilePage({ profileId, ownUserId, onBack }) {
  const [profile, setProfile] = useState(null)
  const [followers, setFollowers] = useState(null)
  const [following, setFollowing] = useState(null)
  const [friends, setFriends] = useState(null)
  const [isFollowing, setIsFollowing] = useState(false)
  const [status, setStatus] = useState('loading')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState({ display_name: '', bio: '' })
  const isOwn = Boolean(ownUserId && profileId === ownUserId)

  const refresh = useCallback(async () => {
    setStatus('loading')
    const { data, error } = await supabase.from('profiles').select('id,username,display_name,bio,avatar_url,created_at').eq('id', profileId).maybeSingle()
    if (error || !data) { setProfile(null); setStatus('error'); return }
    setProfile(data)
    setDraft({ display_name: data.display_name || '', bio: data.bio || '' })
    const results = await Promise.all([
      supabase.from('follows').select('follower_id', { count: 'exact', head: true }).eq('following_id', profileId),
      supabase.from('follows').select('following_id', { count: 'exact', head: true }).eq('follower_id', profileId),
      ownUserId && ownUserId !== profileId
        ? supabase.from('follows').select('following_id').eq('follower_id', ownUserId).eq('following_id', profileId).maybeSingle()
        : Promise.resolve({ data: null, error: null }),
      supabase.from('follows').select('following_id').eq('follower_id', profileId),
      supabase.from('follows').select('follower_id').eq('following_id', profileId),
    ])
    setFollowers(results[0].error ? null : results[0].count)
    setFollowing(results[1].error ? null : results[1].count)
    setIsFollowing(Boolean(results[2].data))
    if (results[3].error || results[4].error) setFriends(null)
    else {
      const incoming = new Set((results[4].data || []).map((row) => row.follower_id))
      setFriends((results[3].data || []).filter((row) => incoming.has(row.following_id)).length)
    }
    setStatus('ready')
  }, [profileId, ownUserId])

  useEffect(() => {
    let cancelled = false
    // Avoid applying a prior account's details while a new profile is loading.
    setProfile(null)
    setFollowers(null)
    setFollowing(null)
    setFriends(null)
    setMessage('')
    async function load() {
      try {
        const { data, error } = await supabase.from('profiles').select('id,username,display_name,bio,avatar_url,created_at').eq('id', profileId).maybeSingle()
        if (cancelled) return
        if (error || !data) { setStatus('error'); return }
        setProfile(data)
        setDraft({ display_name: data.display_name || '', bio: data.bio || '' })
        const [a, b, c] = await Promise.all([
          supabase.from('follows').select('follower_id', { count: 'exact', head: true }).eq('following_id', profileId),
          supabase.from('follows').select('following_id', { count: 'exact', head: true }).eq('follower_id', profileId),
          ownUserId && ownUserId !== profileId ? supabase.from('follows').select('following_id').eq('follower_id', ownUserId).eq('following_id', profileId).maybeSingle() : Promise.resolve({ data: null }),
        ])
        if (cancelled) return
        setFollowers(a.error ? null : a.count)
        setFollowing(b.error ? null : b.count)
        const [outgoing, incoming] = await Promise.all([supabase.from('follows').select('following_id').eq('follower_id', profileId), supabase.from('follows').select('follower_id').eq('following_id', profileId)])
        if (cancelled) return
        if (!outgoing.error && !incoming.error) {
          const mutual = new Set((incoming.data || []).map((row) => row.follower_id))
          setFriends((outgoing.data || []).filter((row) => mutual.has(row.following_id)).length)
        }
        setIsFollowing(Boolean(c.data))
        setStatus('ready')
      } catch { if (!cancelled) setStatus('error') }
    }
    setStatus('loading')
    void load()
    return () => { cancelled = true }
  }, [profileId, ownUserId])

  const toggleFollow = async () => {
    if (!ownUserId || isOwn || busy) return
    setBusy(true); setMessage('')
    const result = isFollowing
      ? await supabase.from('follows').delete().eq('follower_id', ownUserId).eq('following_id', profileId)
      : await supabase.from('follows').insert({ follower_id: ownUserId, following_id: profileId })
    if (result.error) setMessage('Could not update your follow. Please try again.')
    else { setIsFollowing(!isFollowing); await refresh() }
    setBusy(false)
  }

  const saveProfile = async (event) => {
    event.preventDefault()
    if (!isOwn || busy) return
    const display_name = draft.display_name.trim()
    if (!display_name || display_name.length > 60 || draft.bio.length > 300) { setMessage('Use a name of 1–60 characters and a bio of up to 300 characters.'); return }
    setBusy(true); setMessage('')
    const { data, error } = await supabase.from('profiles').update({ display_name, bio: draft.bio.trim() }).eq('id', ownUserId).select('id,username,display_name,bio,avatar_url,created_at').single()
    if (error || !data) setMessage('Changes could not be saved. Please try again.')
    else { setProfile(data); setEditing(false); setMessage('Profile updated.') }
    setBusy(false)
  }

  const name = profile?.display_name || profile?.username || 'Fameverse creator'
  return <main className="fv-profile-page">
    <div className="fv-profile-page-nav"><button type="button" onClick={onBack}>← Discover creators</button><span>PROFILE</span></div>
    {status === 'loading' && <p role="status">Loading profile…</p>}
    {status === 'error' && <section role="alert"><h1>Profile unavailable</h1><p>We could not load this account.</p><button type="button" onClick={onBack}>Back to creators</button></section>}
    {profile && <article className="fv-profile-page-main">
      
      <div className="fv-profile-page-details">
        <div className="fv-profile-page-top">
          <div className="fv-profile-page-avatar"><span>{Array.from(name.trim())[0]?.toUpperCase() || 'F'}</span>{profile.avatar_url && <img src={profile.avatar_url} alt="" onError={(e) => { e.currentTarget.hidden = true }} />}</div>
          <div className="fv-profile-page-actions">
            {isOwn ? <button type="button" onClick={() => { setEditing(!editing); setMessage('') }}>{editing ? 'Cancel' : 'Edit profile'}</button> : ownUserId ? <button type="button" disabled={busy} onClick={toggleFollow}>{busy ? 'Updating…' : isFollowing ? 'Following ✓' : 'Follow +'}</button> : <span>Sign in to follow</span>}
          </div>
        </div>
        <h1>{name}</h1>
        {profile.username && <p className="fv-profile-page-handle">@{profile.username}</p>}
        <p className="fv-profile-page-bio">{profile.bio || 'No bio added yet.'}</p>
        <div className="fv-profile-page-metrics"><div><strong>{followers === null ? '—' : followers.toLocaleString('en-US')}</strong><span>Followers</span></div><div><strong>{following === null ? '—' : following.toLocaleString('en-US')}</strong><span>Following</span></div><div><strong>{friends === null ? '—' : friends.toLocaleString('en-US')}</strong><span>Friends (mutual follows)</span></div></div>
        {message && <p role="status" className="fv-profile-page-message">{message}</p>}
        {isOwn && editing && <form className="fv-profile-page-edit" onSubmit={saveProfile}>
          <label>Display name<input maxLength={60} required value={draft.display_name} onChange={(e) => setDraft({ ...draft, display_name: e.target.value })} /></label>
          <label>Bio<textarea maxLength={300} rows={4} value={draft.bio} onChange={(e) => setDraft({ ...draft, bio: e.target.value })} /></label>
          <button type="submit" disabled={busy}>{busy ? 'Saving…' : 'Save changes'}</button>
        </form>}
        <section className="fv-profile-page-section"><h2>About this creator</h2><p>{profile.bio || 'No additional information yet.'}</p></section>
      </div>
    </article>}
  </main>
}
