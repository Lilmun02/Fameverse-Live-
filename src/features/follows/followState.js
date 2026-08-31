export function getFollowState({ viewerFollows, targetFollows }) {
  if (viewerFollows && targetFollows) {
    return { key: 'friend', label: 'Friend', action: 'unfollow' }
  }

  if (viewerFollows) {
    return { key: 'unfollow', label: 'Unfollow', action: 'unfollow' }
  }

  if (targetFollows) {
    return { key: 'follow-back', label: 'Follow back', action: 'follow' }
  }

  return { key: 'follow', label: 'Follow', action: 'follow' }
}
