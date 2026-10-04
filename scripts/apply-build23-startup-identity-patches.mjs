import { readFile, writeFile } from 'node:fs/promises'
import './apply-payout-provider-wiring.mjs'
import './apply-verification-moderation-wiring.mjs'
import './apply-build32-rankings.mjs'

const root = new URL('../', import.meta.url)

async function read(path) {
  return readFile(new URL(path, root), 'utf8'
  )
}

async function write(path, content) {
  await writeFile(new URL(path, root), content, 'utf8')
}

function countOccurrences(content, marker) {
  let count = 0
  let index = 0
  while ((index = content.indexOf(marker, index)) !== -1) {
    count += 1
    index += marker.length
  }
  return count
}

function removeDuplicateMethod(content, marker) {
  const positions = []
  let cursor = 0
  while ((cursor = content.indexOf(marker, cursor)) !== -1) {
    positions.push(cursor)
    cursor += marker.length
  }
  if (positions.length <= 1) return content

  let next = content
  for (let i = positions.length - 1; i >= 1; i -= 1) {
    const markerIndex = next.lastIndexOf(marker)
    const signatureStart = next.lastIndexOf('  Future<', markerIndex)
    if (signatureStart === -1) {
      throw new Error('[build23-final-patch] could not locate duplicate method signature')
    }
    const openBrace = next.indexOf('{', markerIndex)
    if (openBrace === -1) {
      throw new Error('[build23-final-patch] could not locate duplicate method body')
    }

    let depth = 0
    let end = -1
    for (let j = openBrace; j < next.length; j += 1) {
      if (next[j] === '{') depth += 1
      if (next[j] === '}') {
        depth -= 1
        if (depth === 0) {
          end = j + 1
          while (end < next.length && next[end] === '\n') end += 1
          break
        }
      }
    }
    if (end === -1) {
      throw new Error('[build23-final-patch] duplicate method braces were unbalanced')
    }
    next = next.slice(0, signatureStart) + next.slice(end)
  }
  return next
}

let changed = false

const appPath = 'native/flutter_v1/lib/app/fameverse_app.dart'
const shellPath = 'native/flutter_v1/lib/features/shell/fameverse_shell_build23.dart'
const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart'

let app = await read(appPath)
if (!app.includes('WidgetsBinding.instance.addPostFrameCallback')) {
  throw new Error('[build23-final-patch] visible splash timer is not first-frame anchored')
}
if (app.includes('Duration(milliseconds: 1500)')) {
  app = app.replace(
    'Duration(milliseconds: 1500)',
    'Duration(milliseconds: 2500)',
  )
  await write(appPath, app)
  changed = true
}
if (!app.includes('Duration(milliseconds: 2500)')) {
  throw new Error('[build23-final-patch] 2500ms visible splash floor is missing')
}
if (!app.includes('width: 94') || !app.includes('height: 94')) {
  throw new Error('[build23-final-patch] compact splash mark is missing')
}

let shell = await read(shellPath)
const identityMarker = '_loadAuthoritativeAccount() async {'
const identityCount = countOccurrences(shell, identityMarker)
if (identityCount === 0) {
  throw new Error('[build23-final-patch] authoritative account loader is missing')
}
if (identityCount > 1) {
  shell = removeDuplicateMethod(shell, identityMarker)
  changed = true
}

for (const required of [
  'get_my_fameverse_identity',
  "throw StateError('current-account-mismatch')",
  'final account = await _loadAuthoritativeAccount();',
  "if (account.role == 'owner')",
  'Future<void> _openCreatorStudio(FvProfile profile) async',
]) {
  if (!shell.includes(required)) {
    throw new Error(`[build23-final-patch] required owner identity contract missing: ${required}`)
  }
}

if (identityCount > 1) await write(shellPath, shell)

const profile = await read(profilePath)
if (!profile.includes("label: isOwner ? 'Owner Control Center' : 'Creator Studio'")) {
  throw new Error('[build23-final-patch] Owner Control Center settings label is missing')
}

console.log(
  changed
    ? '[build23-final-patch] Applied/persisted startup or identity repair; contracts remain intact.'
    : '[build23-final-patch] Startup/identity source is already clean and idempotent.',
)
