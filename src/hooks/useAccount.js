import { useEffect, useState } from 'react'
import { uploadProfileAvatar } from '../services/profileAvatars.js'
import { supabase } from '../services/supabase.js'
import { cleanUsername } from '../utils/profile.js'

const PROFILE_FIELDS = 'id, username, display_name, bio, avatar_url, created_at, updated_at'

export function useAccount({ setToast, onBeforeSignOut }) {
  const [authReady, setAuthReady] = useState(false)
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [profileBusy, setProfileBusy] = useState(false)
  const [authMode, setAuthMode] = useState('signin')
  const [authForm, setAuthForm] = useState({ email: '', password: '', displayName: '' })
  const [authMessage, setAuthMessage] = useState('')
  const [profileDraft, setProfileDraft] = useState({ display_name: '', username: '', bio: '' })

  useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      setAuthReady(true)
    }).catch(() => setAuthReady(true))

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setAuthReady(true)
    })

    return () => {
      mounted = false
      authListener.subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    if (!session?.user?.id) {
      setProfile(null)
      return
    }

    let active = true
    const loadProfile = async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select(PROFILE_FIELDS)
        .eq('id', session.user.id)
        .single()

      if (!active) return
      if (error) {
        setToast('Signed in · profile is still initializing')
        return
      }

      setProfile(data)
      setProfileDraft({
        display_name: data.display_name || '',
        username: data.username || '',
        bio: data.bio || '',
      })
    }

    loadProfile()
    return () => { active = false }
  }, [session?.user?.id, setToast])

  const submitAuth = async (event) => {
    event.preventDefault()
    setAuthMessage('')
    if (!authForm.email || !authForm.password) {
      setAuthMessage('Email and password are required.')
      return
    }

    if (authMode === 'signup') {
      const { data, error } = await supabase.auth.signUp({
        email: authForm.email.trim(),
        password: authForm.password,
        options: { data: { display_name: authForm.displayName.trim() || 'Fameverse User' } },
      })
      if (error) {
        setAuthMessage(error.message)
        return
      }
      setAuthMessage(data.session ? 'Account created.' : 'Account created. Sign in to continue.')
      return
    }

    const { error } = await supabase.auth.signInWithPassword({
      email: authForm.email.trim(),
      password: authForm.password,
    })
    if (error) setAuthMessage(error.message)
  }

  const saveProfile = async (event, avatarFile = null) => {
    event?.preventDefault?.()
    if (!session?.user?.id || profileBusy) return false

    const nextUsername = cleanUsername(profileDraft.username)
    if (profileDraft.username && nextUsername.length < 3) {
      setToast('Username must be at least 3 characters')
      return false
    }

    setProfileBusy(true)
    let avatarUrl = profile?.avatar_url || null

    if (avatarFile) {
      try {
        avatarUrl = await uploadProfileAvatar(session.user.id, avatarFile)
      } catch (error) {
        setProfileBusy(false)
        setToast(error?.message || 'Could not upload profile photo')
        return false
      }
    }

    const { data, error } = await supabase
      .from('profiles')
      .update({
        display_name: profileDraft.display_name.trim() || 'Fameverse User',
        username: nextUsername || null,
        bio: profileDraft.bio.trim().slice(0, 160),
        avatar_url: avatarUrl,
      })
      .eq('id', session.user.id)
      .select(PROFILE_FIELDS)
      .single()

    setProfileBusy(false)

    if (error) {
      setToast(error.code === '23505' ? 'That username is already taken' : 'Could not save profile')
      return false
    }

    setProfile(data)
    setProfileDraft({
      display_name: data.display_name || '',
      username: data.username || '',
      bio: data.bio || '',
    })
    setToast(avatarFile ? 'Profile and photo saved' : 'Profile saved')
    return true
  }

  const signOut = async () => {
    onBeforeSignOut?.()
    await supabase.auth.signOut()
  }

  return {
    authReady,
    session,
    profile,
    profileBusy,
    authMode,
    setAuthMode,
    authForm,
    setAuthForm,
    authMessage,
    setAuthMessage,
    profileDraft,
    setProfileDraft,
    submitAuth,
    saveProfile,
    signOut,
  }
}
