import { useEffect, useState } from 'react'
import {
  getCurrentSession,
  signInWithEmail,
  signOutAccount,
  signUpWithEmail,
  subscribeToAuthChanges,
} from '../systems/account/authSystem.js'
import {
  emptyProfileDraft,
  loadProfile,
  profileToDraft,
  saveProfile as saveProfileRecord,
} from '../systems/account/profileSystem.js'

export function useAccount({ setToast, onBeforeSignOut }) {
  const [authReady, setAuthReady] = useState(false)
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [profileBusy, setProfileBusy] = useState(false)
  const [authMode, setAuthMode] = useState('signin')
  const [authForm, setAuthForm] = useState({ email: '', password: '', displayName: '' })
  const [authMessage, setAuthMessage] = useState('')
  const [profileDraft, setProfileDraft] = useState(emptyProfileDraft)

  useEffect(() => {
    let mounted = true
    getCurrentSession().then((nextSession) => {
      if (!mounted) return
      setSession(nextSession)
      setAuthReady(true)
    }).catch(() => setAuthReady(true))

    const unsubscribe = subscribeToAuthChanges((nextSession) => {
      setSession(nextSession)
      setAuthReady(true)
    })

    return () => {
      mounted = false
      unsubscribe()
    }
  }, [])

  useEffect(() => {
    if (!session?.user?.id) {
      setProfile(null)
      setProfileDraft(emptyProfileDraft())
      return
    }

    let active = true
    const hydrateProfile = async () => {
      const { data, error } = await loadProfile(session.user.id)
      if (!active) return
      if (error) {
        setToast('Signed in · profile is still initializing')
        return
      }
      setProfile(data)
      setProfileDraft(profileToDraft(data))
    }

    hydrateProfile()
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
      const { data, error } = await signUpWithEmail(authForm)
      if (error) {
        setAuthMessage(error.message)
        return
      }
      setAuthMessage(data.session ? 'Account created.' : 'Account created. Sign in to continue.')
      return
    }

    const { error } = await signInWithEmail(authForm)
    if (error) setAuthMessage(error.message)
  }

  const saveProfile = async (event) => {
    event.preventDefault()
    if (!session?.user?.id) return false

    setProfileBusy(true)
    const result = await saveProfileRecord(session.user.id, profileDraft)
    setProfileBusy(false)

    if (result.validationError) {
      setToast(result.validationError)
      return false
    }

    if (result.error) {
      setToast(result.error.code === '23505' ? 'That username is already taken' : 'Could not save profile')
      return false
    }

    setProfile(result.data)
    setProfileDraft(profileToDraft(result.data))
    setToast('Profile saved')
    return true
  }

  const signOut = async () => {
    onBeforeSignOut?.()
    await signOutAccount()
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
