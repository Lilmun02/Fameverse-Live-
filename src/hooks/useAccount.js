import { useEffect, useState } from 'react'
import { loadAccountRole } from '../services/accountRoles.js'
import { uploadProfileAvatar } from '../services/profileAvatars.js'
import { recoveryLinkPresented, supabase } from '../services/supabase.js'
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
  const [recoveryMode, setRecoveryMode] = useState(() => window.location.pathname === '/reset-password')
  const [recoveryPassword, setRecoveryPassword] = useState('')
  const [recoveryAuthorized, setRecoveryAuthorized] = useState(false)
  const [resetRequestBusy, setResetRequestBusy] = useState(false)
  const [resetCooldownUntil, setResetCooldownUntil] = useState(0)
  const [profileDraft, setProfileDraft] = useState({ display_name: '', username: '', bio: '' })

  useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session)
      setAuthReady(true)
    }).catch(() => setAuthReady(true))

    const { data: authListener } = supabase.auth.onAuthStateChange((event, nextSession) => {
      if (event === 'PASSWORD_RECOVERY' || (recoveryLinkPresented && nextSession?.user && (event === 'SIGNED_IN' || event === 'INITIAL_SESSION'))) {
        setRecoveryAuthorized(true)
        setRecoveryMode(true)
      }
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
      const [profileResult, accountRole] = await Promise.all([
        supabase
          .from('profiles')
          .select(PROFILE_FIELDS)
          .eq('id', session.user.id)
          .single(),
        loadAccountRole(session.user.id),
      ])

      if (!active) return
      if (profileResult.error) {
        setToast('Signed in · profile is still initializing')
        return
      }

      const data = profileResult.data
      setProfile({ ...data, account_role: accountRole })
      setProfileDraft({
        display_name: data.display_name || '',
        username: data.username || '',
        bio: data.bio || '',
      })
    }

    loadProfile().catch(() => {
      if (active) setToast('Signed in · profile identity is still initializing')
    })
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

  const requestPasswordReset = async () => {
    if (resetRequestBusy) return
    const email = authForm.email.trim()
    if (!email) return setAuthMessage('Enter your email address first.')
    const remaining = Math.ceil((resetCooldownUntil - Date.now()) / 1000)
    if (remaining > 0) return setAuthMessage(`Please wait ${remaining} seconds before requesting another reset email.`)

    setResetRequestBusy(true)
    setAuthMessage('')
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: 'https://fameverse.app/reset-password',
      })
      if (error) {
        if (error.status === 429 || error.code === 'over_email_send_rate_limit' || error.code === 'over_request_rate_limit') {
          const retrySeconds = Number(error.message?.match(/after (\\d+) seconds?/i)?.[1]) || 60
          setResetCooldownUntil(Date.now() + retrySeconds * 1000)
          setAuthMessage(`Too many reset requests. Please wait ${retrySeconds} seconds before trying again.`)
        } else {
          setAuthMessage('Unable to send a reset email right now. Please try again later.')
        }
        return
      }
      setResetCooldownUntil(Date.now() + 60_000)
      setAuthMessage('If that account exists, check your email (including spam) for a reset link. Wait 60 seconds before requesting another.')
    } catch {
      setAuthMessage('Network error while requesting reset. Check your connection and try again.')
    } finally {
      setResetRequestBusy(false)
    }
  }

  const completePasswordReset = async (event) => {
    event.preventDefault()
    if (recoveryPassword.length < 8) return setAuthMessage('Use at least 8 characters.')
    if (!session?.user || !recoveryAuthorized) return setAuthMessage('Reset link expired or invalid. Request a new password reset email.')
    const { error } = await supabase.auth.updateUser({ password: recoveryPassword })
    if (error) return setAuthMessage('Unable to update password. Request a fresh reset link.')
    setRecoveryPassword('')
    setRecoveryAuthorized(false)
    setRecoveryMode(false)
    setAuthMessage('Password updated successfully.')
    window.history.replaceState({}, '', '/')
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

    setProfile({ ...data, account_role: profile?.account_role || null })
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
    recoveryMode, recoveryAuthorized, recoveryPassword, setRecoveryPassword, requestPasswordReset, resetRequestBusy, completePasswordReset,
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
