import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

const criticalFiles = [
  'native/flutter_v1/lib/features/live/native_live_stage.dart',
  'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart',
  'native/flutter_v1/lib/features/live/stream_host_live_screen.dart',
  'native/flutter_v1/lib/features/live/native_live_components.dart',
  'native/flutter_v1/lib/features/live/native_gift_visual.dart',
  'native/flutter_v1/lib/features/live/stream_live_shared.dart',
  'native/flutter_v1/lib/data/fameverse_live_backend.dart',
  'native/flutter_v1/lib/features/profile/native_profile_screen.dart',
  'native/flutter_v1/lib/features/profile/creator_studio_screen.dart',
]

function fingerprint(files) {
  const hash = createHash('sha256')
  for (const path of files) {
    hash.update(path)
    hash.update('\0')
    hash.update(readFileSync(path))
    hash.update('\0')
  }
  return hash.digest('hex')
}

function requireAllChecks(section, label) {
  assert.equal(section?.status, 'passed', `Release blocked: ${label} physical acceptance is still pending.`)
  for (const [name, passed] of Object.entries(section?.checks ?? {})) {
    assert.equal(passed, true, `Release blocked: ${label} physical check "${name}" has not passed.`)
  }
}

const manifest = JSON.parse(
  readFileSync('docs/BUILD18_NATIVE_PHYSICAL_ACCEPTANCE.json', 'utf8'),
)

assert.equal(manifest.build, 18, 'Release blocked: native physical acceptance manifest is not for Build 18.')
assert.equal(manifest.status, 'passed', 'Release blocked: Build 18 native physical acceptance is still pending.')
requireAllChecks(manifest.owner_iphone, 'owner iPhone')
requireAllChecks(manifest.external_tester_iphone, 'external tester iPhone')

assert.match(
  manifest.tested_commit || '',
  /^[0-9a-f]{40}$/i,
  'Release blocked: native tested_commit is missing or invalid.',
)
assert.match(
  manifest.fingerprint || '',
  /^[0-9a-f]{64}$/i,
  'Release blocked: native acceptance fingerprint is missing or invalid.',
)

const currentFingerprint = fingerprint(criticalFiles)
assert.equal(
  manifest.fingerprint,
  currentFingerprint,
  'Release blocked: native Live/Profile code changed after physical acceptance. Re-test owner and external tester iPhones.',
)

try {
  execFileSync('git', ['merge-base', '--is-ancestor', manifest.tested_commit, 'HEAD'], {
    stdio: 'ignore',
  })
} catch {
  assert.fail('Release blocked: physically tested native commit is not in this release history.')
}

console.log(
  `Build 18 native physical acceptance passed for ${manifest.tested_commit.slice(0, 12)} with fingerprint ${currentFingerprint.slice(0, 12)}.`,
)
