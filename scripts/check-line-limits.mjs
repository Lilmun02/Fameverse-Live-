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
const appSource = await readFile(join(sourceRoot, 'App.jsx'), 'utf8')
const hostLiveV2Active = appSource.includes("import HostLiveV2 from './components/live/HostLiveV2.jsx'")
  && appSource.includes('<HostLiveV2')
  && appSource.includes("tab === 'live'")

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
  const content = await readFile(join(sourceRoot, guard.file), 'utf8')
  if (!guard.snippets.every((snippet) => content.includes(snippet))) {
    architectureViolations.push(`${guard.message} Expected in src/${guard.file}`)
  }
}

// Approved Gift Tray V1 contract.
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
    architectureViolations.push('Gift tray contract failed: approved categorized tray and backend-confirmed close-after-send behavior must remain wired.')
  }
}

// Gift pricing/quantity contract.
{
  const giftConfig = await readFile(join(sourceRoot, 'config/gifts.js'), 'utf8')
  const giftTray = await readFile(join(sourceRoot, 'components/gifts/LiveGiftTray.jsx'), 'utf8')
  const giftOverlay = await readFile(join(sourceRoot, 'components/gifts/GiftOverlay.jsx'), 'utf8')
  const basicGiftIds = ['rose', 'heart', 'fire', 'star', 'crown']
  const basicPricesLocked = basicGiftIds.every((id) => new RegExp(`id: '${id}',[^\\n]*cost: 1`).test(giftConfig))
  const welcomePriceLocked = /id: 'welcome-to-fameverse'[\s\S]*?cost: 100/.test(giftConfig)
  const customAmountLocked = giftTray.includes('Custom') && giftTray.includes('Send ×{normalizeQuantity(customQuantity)}')
  const quantityDisplayLocked = giftOverlay.includes('×{giftOverlay.count || 1}')

  if (!basicPricesLocked || !welcomePriceLocked || !customAmountLocked || !quantityDisplayLocked) {
    architectureViolations.push('Gift amount contract failed: simple gifts, Welcome pricing, bounded custom amount, and ×N display must remain locked.')
  }
}

if (hostLiveV2Active) {
  const hostLive = await readFile(join(sourceRoot, 'components/live/HostLiveV2.jsx'), 'utf8')
  const hostCss = await readFile(join(sourceRoot, 'styles/live/host-live-v2.css'), 'utf8')
  const main = await readFile(join(sourceRoot, 'main.jsx'), 'utf8')
  const fullSessionChat = appSource.includes('const liveMessages = chat') && !appSource.includes('const liveMessages = chat.slice(')
  const endLiveIndex = appSource.indexOf('if (wasLive)')
  const endLiveCloseIndex = endLiveIndex >= 0 ? appSource.indexOf('\n    }', endLiveIndex) : -1
  const clearChatIndex = endLiveIndex >= 0 ? appSource.indexOf('setChat([])', endLiveIndex) : -1
  const clearDraftIndex = endLiveIndex >= 0 ? appSource.indexOf("setCommentText('')", endLiveIndex) : -1

  if (!fullSessionChat || !hostLive.includes('node.scrollTop = node.scrollHeight')) {
    architectureViolations.push('Live V2 chat contract failed: retain full session and auto-follow comments.')
  }
  if (!hostCss.includes('.fv2-host-live') || !hostCss.includes('position: fixed') || !hostCss.includes('height: 100dvh')) {
    architectureViolations.push('Live V2 shell contract failed: one fixed full-viewport fv2 shell must own Host Live geometry.')
  }
  if (hostCss.includes('backdrop-filter') || hostCss.includes('filter: blur')) {
    architectureViolations.push('Live V2 clarity contract failed: cloudy/frosted blur is forbidden.')
  }
  if (!main.includes("./styles/live/host-live-v2.css")) {
    architectureViolations.push('Live V2 stylesheet must be loaded by src/main.jsx.')
  }
  if (appSource.includes("import LiveScreen from './components/live/LiveScreen.jsx'") || appSource.includes('<LiveScreen')) {
    architectureViolations.push('Retired Host Live component must not be active beside Live V2.')
  }
  if (
    endLiveIndex < 0
    || endLiveCloseIndex < 0
    || clearChatIndex < 0
    || clearDraftIndex < 0
    || clearChatIndex > endLiveCloseIndex
    || clearDraftIndex > endLiveCloseIndex
  ) {
    architectureViolations.push('Live V2 session contract failed: End must clear chat and draft inside the wasLive cleanup path.')
  }
} else if (appSource.includes('useLiveMedia') || appSource.includes('useLivePresence') || appSource.includes('useLiveBroadcast') || appSource.includes('const startLive')) {
  architectureViolations.push('Host Live runtime is active without the approved HostLiveV2 shell.')
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
console.log(hostLiveV2Active
  ? 'Architecture guard passed: approved Host Live V2 is the only active host shell; clarity, chat, media health, gifts, and End cleanup remain protected.'
  : 'Architecture guard passed: Host Live is absent while shared app contracts remain protected.')
