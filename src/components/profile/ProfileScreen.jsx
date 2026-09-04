import { useEffect, useState } from 'react'
import { legalPages } from '../../config/legal.js'
import { loadGifterStats } from '../../services/gifterLevels.js'
import CreatorStudio from './CreatorStudio.jsx'
import ProfileEdit from './ProfileEdit.jsx'
import ProfileView from './ProfileView.jsx'
import LegalPage from '../settings/LegalPage.jsx'
import SettingsDetail from '../settings/SettingsDetail.jsx'
import SettingsHome from '../settings/SettingsHome.jsx'

export default function ProfileScreen({
  profileMode,
  setProfileMode,
  policyPage,
  setPolicyPage,
  settingsDetail,
  setSettingsDetail,
  creatorTab,
  setCreatorTab,
  session,
  profile,
  displayName,
  username,
  initial,
  joinedLabel,
  shareRoom,
  profileDraft,
  setProfileDraft,
  saveProfile,
  profileBusy,
  signOut,
  setTab,
  followNetwork,
}) {
  const [gifterLevel, setGifterLevel] = useState(1)

  useEffect(() => {
    let active = true
    loadGifterStats(profile?.id)
      .then((stats) => {
        if (active) setGifterLevel(Math.max(1, Number(stats.level || 1)))
      })
      .catch(() => {
        if (active) setGifterLevel(1)
      })
    return () => { active = false }
  }, [profile?.id])

  const openProfileMode = (mode) => {
    setPolicyPage(null)
    setSettingsDetail(null)
    setProfileMode(mode)
  }

  if (profileMode === 'view') {
    return (
      <ProfileView
        initial={initial}
        displayName={displayName}
        username={username}
        profile={profile}
        joinedLabel={joinedLabel}
        openProfileMode={openProfileMode}
        shareRoom={shareRoom}
        creatorTab={creatorTab}
        setCreatorTab={setCreatorTab}
        followers={followNetwork.followers}
        following={followNetwork.following}
        followerCount={followNetwork.followerCount}
        followingCount={followNetwork.followingCount}
        busyTargetId={followNetwork.busyTargetId}
        toggleFollow={followNetwork.toggleFollow}
        gifterLevel={gifterLevel}
      />
    )
  }

  if (profileMode === 'studio') {
    return (
      <CreatorStudio
        openProfileMode={openProfileMode}
        setTab={setTab}
        setCreatorTab={setCreatorTab}
        setProfileMode={setProfileMode}
      />
    )
  }

  if (profileMode === 'edit') {
    return (
      <ProfileEdit
        openProfileMode={openProfileMode}
        profileDraft={profileDraft}
        setProfileDraft={setProfileDraft}
        saveProfile={saveProfile}
        profileBusy={profileBusy}
        profile={profile}
        initial={initial}
        displayName={displayName}
      />
    )
  }

  if (profileMode !== 'settings') return null
  if (policyPage) return <LegalPage page={legalPages[policyPage]} onBack={() => setPolicyPage(null)} />
  if (settingsDetail) return <SettingsDetail type={settingsDetail} email={session.user.email} onBack={() => setSettingsDetail(null)} />

  return (
    <SettingsHome
      session={session}
      openProfileMode={openProfileMode}
      setSettingsDetail={setSettingsDetail}
      setPolicyPage={setPolicyPage}
      signOut={signOut}
    />
  )
}
