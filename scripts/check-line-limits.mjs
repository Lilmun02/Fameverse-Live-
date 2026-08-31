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

// Gift tray invariant: successful gift sends close the tray by default. The only
// allowed exception is an explicitly requested quick-amount tap (1×/5×/10×),
// which keeps the tray open so the sender can tap another amount. The tray UI
// owns amount selection; the hook owns transaction/close behavior.
{
  const giftHook = await readFile(join(sourceRoot, 'hooks/useGiftSystem.js'), 'utf8')
  const giftTray = await readFile(join(sourceRoot, 'components/gifts/LiveGiftTray.jsx'), 'utf8')
  const acceptedChatIndex = giftHook.indexOf('setChat((items)')
  const rendererBranchIndex = giftHook.indexOf('if (gift.rendererId)')
  const conditionalCloseIndex = acceptedChatIndex >= 0
    ? giftHook.indexOf('if (!keepTrayOpen) setGiftTrayOpen(false)', acceptedChatIndex)
    : -1
  const quickAmountsDeclared = giftTray.includes('const QUICK_GIFT_AMOUNTS = [1, 5, 10]')
  const quickSendKeepsTrayOpen = giftTray.includes('sendGift(gift, quantity, { keepTrayOpen: true })')

  if (
    acceptedChatIndex < 0
    || rendererBranchIndex < 0
    || conditionalCloseIndex < 0
    || conditionalCloseIndex > rendererBranchIndex
    || !quickAmountsDeclared
    || !quickSendKeepsTrayOpen
  ) {
    architectureViolations.push(
      'Gift tray contract failed: successful sends must close by default, while only 1×/5×/10× quick-amount taps may explicitly keep the tray open.',
    )
  }
}

// Gift amount/pricing invariant: current non-cinematic beta gifts remain 1 coin
// each, quick amounts remain 1×/5×/10×, custom amount remains available, and
// every simple gift presentation visibly includes the actual ×N quantity.
{
  const giftConfig = await readFile(join(sourceRoot, 'config/gifts.js'), 'utf8')
  const giftTray = await readFile(join(sourceRoot, 'components/gifts/LiveGiftTray.jsx'), 'utf8')
  const giftOverlay = await readFile(join(sourceRoot, 'components/gifts/GiftOverlay.jsx'), 'utf8')
  const basicGiftIds = ['rose', 'heart', 'fire', 'star', 'crown']
  const basicPricesLocked = basicGiftIds.every((id) => {
    const pattern = new RegExp(`id: '${id}',[^\\n]*cost: 1`)
    return pattern.test(giftConfig)
  })
  const quickAmountsLocked = giftTray.includes('const QUICK_GIFT_AMOUNTS = [1, 5, 10]')
  const customAmountLocked = giftTray.includes('Custom amount')
    && giftTray.includes('Send ×{amountValue')
  const quantityDisplayLocked = giftOverlay.includes('×{giftOverlay.count || 1}')

  if (
    !basicPricesLocked
    || !quickAmountsLocked
    || !customAmountLocked
    || !quantityDisplayLocked
  ) {
    architectureViolations.push(
      'Gift amount contract failed: basic gifts must stay 1 coin, 1×/5×/10× quick amounts and custom amount must remain available, and simple gift overlays must always display ×N.',
    )
  }
}

// Live chat scrolling invariant: the whole session stays available, new messages
// auto-follow inside the chat region, and the Live shell itself never becomes the
// scroll target on iOS/PWA. LiveChat owns scroll behavior; polish.css owns the
// pinned shell/scroll viewport contract.
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
      'Live chat scrolling contract failed: retain the full session, auto-follow new comments, keep chat vertically scrollable, and keep the Live shell pinned/non-scrollable.',
    )
  }
}

// Live session invariant: ending a Live must clear both committed chat messages
// and the unsent comment draft inside the End Live path.
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
console.log('Architecture guard passed: startup recovery, media health, gift tray quick-amount exception, gift amount/pricing, live chat scrolling, and End Live chat reset contracts are active; disabled media wrappers are not imported.')
