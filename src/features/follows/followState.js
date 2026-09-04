export function getFollowState({ viewerFollows, targetFollows }) {
  if (viewerFollows && targetFollows) {
    return { key: 'friend', label: 'Friends', action: 'unfollow' }
  }

  if (viewerFollows) {
    return { key: 'unfollow', label: 'Following', action: 'unfollow' }
  }

  if (targetFollows) {
    return { key: 'follow-back', label: 'Follow Back', action: 'follow' }
  }

  return { key: 'follow', label: 'Follow', action: 'follow' }
}
