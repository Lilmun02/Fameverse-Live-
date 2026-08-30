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

  if (lines > MAX_LINES) {
    violations.push({ file: rel, lines })
  }

  if (!rel.startsWith('legacy/disabled/')) {
    for (const forbidden of FORBIDDEN_ACTIVE_IMPORTS) {
      const importPattern = new RegExp(`(?:import|from)\\s*['\"][^'\"]*${forbidden.replace('.', '\\.')}[^'\"]*['\"]`)
      if (importPattern.test(content)) {
        architectureViolations.push(`src/${rel} imports disabled legacy media code (${forbidden}).`)
      }
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

// Gift tray invariant: after a gift has been accepted into chat, the tray must
// close on the shared success path before renderer-specific branching. This
// prevents simple gifts from losing the close behavior during future refactors.
{
  const giftHookPath = join(sourceRoot, 'hooks/useGiftSystem.js')
  const giftHook = await readFile(giftHookPath, 'utf8')
  const acceptedChatIndex = giftHook.indexOf('setChat((items)')
  const rendererBranchIndex = giftHook.indexOf('if (gift.rendererId)')
  const sharedCloseIndex = acceptedChatIndex >= 0
    ? giftHook.indexOf('setGiftTrayOpen(false)', acceptedChatIndex)
    : -1

  if (
    acceptedChatIndex < 0
    || rendererBranchIndex < 0
    || sharedCloseIndex < 0
    || sharedCloseIndex > rendererBranchIndex
  ) {
    architectureViolations.push(
      'Gift tray contract failed: every successful gift send must close the tray on the shared path before renderer-specific branching. Expected in src/hooks/useGiftSystem.js',
    )
  }
}

// Live session invariant: ending a Live must clear both committed chat messages
// and the unsent comment draft. These states are App-owned and must reset inside
// the End Live path so no room text leaks into the next session.
{
  const appPath = join(sourceRoot, 'App.jsx')
  const app = await readFile(appPath, 'utf8')
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
  for (const violation of violations) {
    console.error(`- src/${violation.file}: ${violation.lines} lines`)
  }
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
console.log('Architecture guard passed: startup recovery, media health, successful-send gift tray close, and End Live chat reset contracts are active; disabled media wrappers are not imported.')
