export const GROK_WELCOME_VIDEO = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/8d3fd7e2-9073-4e1b-8ef6-843a1514aae6.mp4'
export const EMBER_DRAGON_VIDEO = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/6ef5d526-e0d8-42ca-a382-28d53d3fe2aa.mp4'
export const CELESTIAL_PHOENIX_VIDEO = 'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/e4da59e7-2d55-4ee2-b546-cae61cf56de3.mp4'

// Custom beta gift sends may be large for progression/load testing, but remain bounded.
export const MAX_BETA_GIFT_QUANTITY = 100000

export const gifts = [
  {
    id: 'welcome-to-fameverse',
    label: 'Welcome to Fameverse',
    cost: 100,
    category: 'fameverse',
    activityEmoji: '✦',
    rendererId: 'welcome-to-fameverse',
    video: GROK_WELCOME_VIDEO,
    poster: '/gifts/welcome-to-fameverse-poster.webp',
    cinematic: true,
  },
  {
    id: 'ember-dragon',
    label: 'Ember Dragon',
    cost: 1000,
    category: 'fameverse',
    activityEmoji: '🐉',
    rendererId: 'ember-dragon',
    video: EMBER_DRAGON_VIDEO,
    poster: '/gifts/ember-dragon-poster.jpg',
    thumbnailTime: 4.2,
    cinematic: true,
    singleSendOnly: true,
  },
  {
    id: 'celestial-phoenix',
    label: 'Celestial Phoenix',
    cost: 1000,
    category: 'fameverse',
    activityEmoji: '🔥',
    rendererId: 'celestial-phoenix',
    video: CELESTIAL_PHOENIX_VIDEO,
    poster: '/gifts/celestial-phoenix-poster.jpg',
    thumbnailTime: 7,
    cinematic: true,
    singleSendOnly: true,
  },
  { id: 'rose', emoji: '🌹', label: 'Rose', cost: 1, category: 'classic' },
  { id: 'heart', emoji: '💜', label: 'Heart', cost: 1, category: 'classic' },
  { id: 'fire', emoji: '🔥', label: 'Fire', cost: 1, category: 'classic' },
  { id: 'star', emoji: '⭐', label: 'Star', cost: 1, category: 'classic' },
  { id: 'crown', emoji: '👑', label: 'Crown', cost: 1, category: 'classic' },
]
