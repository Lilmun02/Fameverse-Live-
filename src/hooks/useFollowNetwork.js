import { useCallback, useEffect, useMemo, useState } from 'react'
import { getFollowState } from '../features/follows/followState.js'
import { followUser, loadFollowNetwork, unfollowUser } from '../services/follows.js'

export function useFollowNetwork({ userId, setToast }) {
  const [network, setNetwork] = useState({ incoming: [], outgoing: [], profiles: [] })
  const [busyTargetId, setBusyTargetId] = useState(null)

  const refresh = useCallback(async () => {
    if (!userId) {
      setNetwork({ incoming: [], outgoing: [], profiles: [] })
      return
    }

    try {
      setNetwork(await loadFollowNetwork(userId))
    } catch {
      setToast('Could not load followers')
    }
  }, [setToast, userId])

  useEffect(() => {
    refresh()
  }, [refresh])

  const incomingIds = useMemo(() => new Set(network.incoming.map((item) => item.follower_id)), [network.incoming])
  const outgoingIds = useMemo(() => new Set(network.outgoing.map((item) => item.following_id)), [network.outgoing])
  const profileMap = useMemo(() => new Map(network.profiles.map((profile) => [profile.id, profile])), [network.profiles])

  const decorate = useCallback((targetId) => {
    const viewerFollows = outgoingIds.has(targetId)
    const targetFollows = incomingIds.has(targetId)
    return {
      ...(profileMap.get(targetId) || { id: targetId, display_name: 'Fameverse User', username: null }),
      relation: getFollowState({ viewerFollows, targetFollows }),
    }
  }, [incomingIds, outgoingIds, profileMap])

  const followers = useMemo(
    () => network.incoming.map((item) => decorate(item.follower_id)),
    [decorate, network.incoming],
  )

  const following = useMemo(
    () => network.outgoing.map((item) => decorate(item.following_id)),
    [decorate, network.outgoing],
  )

  const toggleFollow = async (targetId) => {
    if (!userId || !targetId || userId === targetId || busyTargetId) return

    const viewerFollows = outgoingIds.has(targetId)
    setBusyTargetId(targetId)
    try {
      if (viewerFollows) await unfollowUser(userId, targetId)
      else await followUser(userId, targetId)
      await refresh()
    } catch {
      setToast(viewerFollows ? 'Could not unfollow' : 'Could not follow')
    } finally {
      setBusyTargetId(null)
    }
  }

  return {
    followers,
    following,
    followerCount: network.incoming.length,
    followingCount: network.outgoing.length,
    busyTargetId,
    toggleFollow,
    refresh,
  }
}
