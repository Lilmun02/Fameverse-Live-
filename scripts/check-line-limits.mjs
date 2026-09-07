import { readdir, readFile } from 'node:fs/promises'
import { extname, join, relative } from 'node:path'

const ROOT = new URL('../src/', import.meta.url)
const MAX_LINES = 450
const CHECKED_EXTENSIONS = new Set(['.js', '.jsx', '.css'])
const FORBIDDEN_ACTIVE_IMPORTS = ['legacy/disabled', 'media-session.js', 'flip-guard.js']
const REQUIRED_GUARDS = [
  {
    file: 'services/supabase.js',
    snippets: ['AUTH_STARTUP_TIMEOUT_MS = 10000', 'Promise.race'],
    message: 'FAM-9 bounded auth startup guard is missing.',
  },
  {
    file: 'hooks/useLiveMedia.js',
    snippets: ['MEDIA_HEALTH_INTERVAL_MS = 4000', "videoTrack.readyState !== 'ended'"],
    message: 'FAM-8 React-owned live media health guard is missing.',
  },
]

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const files = []
  for (const entry of entries) {
    const fullPath = join(directory, entry.name)
    if (entry.isDirectory()) files.push(...await walk(fullPath))
    else if (CHECKED_EXTENSIONS.has(extname(entry.name))) files.push(fullPath)
  }
  return files
}

const sourceRoot = ROOT.pathname
const files = await walk(sourceRoot)
const violations = []
const architectureViolations = []

for (const file of files) {
  const content = await readFile(file, 'utf8')
  const rel = relative(sourceRoot, file).replaceAll('\\', '/')
  const lines = content === '' ? 0 : content.split(/\r?\n/).length
  if (lines > MAX_LINES) violations.push({ file: rel, lines })

  if (!rel.startsWith('legacy/disabled/')) {
    for (const forbidden of FORBIDDEN_ACTIVE_IMPORTS) {
      const importPattern = new RegExp(`(?:import|from)\\s*['\"][^'\"]*${forbidden.replace('.', '\\.')}[^'\"]*['\"]`)
      if (importPattern.test(content)) architectureViolations.push(`src/${rel} imports disabled legacy media code (${forbidden}).`)
    }
  }
}

for (const guard of REQUIRED_GUARDS) {
  const filePath = join(sourceRoot, guard.file)
  const content = await readFile(filePath, 'utf8')
  if (!guard.snippets.every((snippet) => content.includes(snippet))) {
    architectureViolations.push(`${guard.message} Expected in src/${guard.file}`)
  }
}

// Approved Gift Tray V1: compact categorized tray, one selected gift action,
// custom amount in its own mini sheet, and successful sends close only after
// useGiftSystem receives server-authoritative acceptance.
{
  const giftHook = await readFile(join(sourceRoot, 'hooks/useGiftSystem.js'), 'utf8')
  const giftTray = await readFile(join(sourceRoot, 'components/gifts/LiveGiftTray.jsx'), 'utf8')
  const acceptedChatIndex = giftHook.indexOf('setChat((items)')
  const rendererBranchIndex = giftHook.indexOf('if (gift.rendererId)')
  const conditionalCloseIndex = acceptedChatIndex >= 0
    ? giftHook.indexOf('if (!keepTrayOpen) setGiftTrayOpen(false)', acceptedChatIndex)
    : -1
  const categoriesLocked = giftTray.includes('const CATEGORIES = [')
    && giftTray.includes("{ id: 'classic', label: 'Classic' }")
    && giftTray.includes("{ id: 'fameverse', label: 'Fameverse' }")
  const customSheetLocked = giftTray.includes('fv-gift-custom-sheet')
    && giftTray.includes('CUSTOM_PRESETS = [5, 10, 25, 50]')
    && giftTray.includes('max={MAX_BETA_GIFT_QUANTITY}')
  const selectedSendLocked = giftTray.includes('sendGift(selectedGift, 1)')
    && giftTray.includes('sendGift(selectedGift, quantity)')
    && !giftTray.includes('keepTrayOpen: true')

  if (
    acceptedChatIndex < 0
    || rendererBranchIndex < 0
    || conditionalCloseIndex < 0
    || conditionalCloseIndex > rendererBranchIndex
    || !categoriesLocked
    || !customSheetLocked
    || !selectedSendLocked
  ) {
    architectureViolations.push(
      'Gift tray contract failed: categorized compact tray, separate custom sheet, selected gift sends, and backend-confirmed close-after-send behavior must remain wired.',
    )
  }
}

// Pricing/quantity law: current simple beta gifts remain 1 coin, Welcome remains
// 100 coins, custom amount remains bounded, and on-screen simple gifts show ×N.
{
  const giftConfig = await readFile(join(sourceRoot, 'config/gifts.js'), 'utf8')
  const giftTray = await readFile(join(sourceRoot, 'components/gifts/LiveGiftTray.jsx'), 'utf8')
  const giftOverlay = await readFile(join(sourceRoot, 'components/gifts/GiftOverlay.jsx'), 'utf8')
  const basicGiftIds = ['rose', 'heart', 'fire', 'star', 'crown']
  const basicPricesLocked = basicGiftIds.every((id) => {
    const pattern = new RegExp(`id: '${id}',[^\\n]*cost: 1`)
    return pattern.test(giftConfig)
  })
  const welcomePriceLocked = /id: 'welcome-to-fameverse'[\s\S]*?cost: 100/.test(giftConfig)
  const customAmountLocked = giftTray.includes('Custom')
    && giftTray.includes('Send ×{normalizeQuantity(customQuantity)}')
  const quantityDisplayLocked = giftOverlay.includes('×{giftOverlay.count || 1}')

  if (!basicPricesLocked || !welcomePriceLocked || !customAmountLocked || !quantityDisplayLocked) {
    architectureViolations.push(
      'Gift amount contract failed: simple gifts must stay 1 coin, Welcome 100 coins, bounded custom amount must remain available, and simple overlays must display ×N.',
    )
  }
}

// Live chat scrolling invariant.
{
  const app = await readFile(join(sourceRoot, 'App.jsx'), 'utf8')
  const liveChat = await readFile(join(sourceRoot, 'components/live/LiveChat.jsx'), 'utf8')
  const livePolish = await readFile(join(sourceRoot, 'styles/live/polish.css'), 'utf8')
  const fullSessionChat = app.includes('const liveMessages = chat') && !app.includes('const liveMessages = chat.slice(')
  const autoFollow = liveChat.includes('chatNode.scrollTop = chatNode.scrollHeight')
    && liveChat.includes('ref={chatScrollRef}')
  const chatOwnsScroll = livePolish.includes('.mobile-live-shell.is-live .live-chat-overlay')
    && livePolish.includes('overflow-y: auto')
    && livePolish.includes('touch-action: pan-y')
    && livePolish.includes('pointer-events: auto')
  const shellPinned = livePolish.includes('.live-app-shell {')
    && livePolish.includes('position: fixed')
    && livePolish.includes('overflow: hidden')

  if (!fullSessionChat || !autoFollow || !chatOwnsScroll || !shellPinned) {
    architectureViolations.push(
      'Live chat scrolling contract failed: retain full session, auto-follow comments, keep chat scrollable, and keep Live shell pinned.',
    )
  }
}

// End Live must clear both committed chat and the unsent draft.
{
  const app = await readFile(join(sourceRoot, 'App.jsx'), 'utf8')
  const endLiveIndex = app.indexOf('if (wasLive)')
  const endLiveCloseIndex = endLiveIndex >= 0 ? app.indexOf('\n    }', endLiveIndex) : -1
  const clearChatIndex = endLiveIndex >= 0 ? app.indexOf('setChat([])', endLiveIndex) : -1
  const clearDraftIndex = endLiveIndex >= 0 ? app.indexOf("setCommentText('')", endLiveIndex) : -1

  if (
    endLiveIndex < 0
    || endLiveCloseIndex < 0
    || clearChatIndex < 0
    || clearDraftIndex < 0
    || clearChatIndex > endLiveCloseIndex
    || clearDraftIndex > endLiveCloseIndex
  ) {
    architectureViolations.push(
      'Live session contract failed: End Live must clear chat and comment draft inside the wasLive cleanup path. Expected in src/App.jsx',
    )
  }
}

if (violations.length) {
  console.error(`Fameverse source limit exceeded (${MAX_LINES} lines max):`)
  for (const violation of violations) console.error(`- src/${violation.file}: ${violation.lines} lines`)
}

if (architectureViolations.length) {
  console.error('Fameverse architecture guard failed:')
  for (const violation of architectureViolations) console.error(`- ${violation}`)
}

if (violations.length || architectureViolations.length) {
  console.error('Split or repair the affected responsibility before merging or deploying.')
  process.exit(1)
}

console.log(`Source line guard passed: ${files.length} files checked, all <= ${MAX_LINES} lines.`)
console.log('Architecture guard passed: startup recovery, media health, approved compact gift tray, gift pricing/quantity, live chat scrolling, and End Live cleanup contracts are active.')
