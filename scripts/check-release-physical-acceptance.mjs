import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

const criticalFiles = [
  'src/App.jsx',
  'src/services/live/webrtcPeer.js',
  'src/hooks/useCohostHost.js',
  'src/hooks/useCohostViewer.js',
  'src/components/live/CohostVideoTile.jsx',
  'src/components/live/ViewerLiveScreen.jsx',
  'src/components/live/LiveScreen.jsx',
  'src/styles/live/cohost.css',
]

function fingerprint(files) {
  const hash = createHash('sha256')
  files.forEach((path) => {
    hash.update(path)
    hash.update('\0')
    hash.update(readFileSync(path))
    hash.update('\0')
  })
  return hash.digest('hex')
}

const manifest = JSON.parse(readFileSync('docs/PHYSICAL_ACCEPTANCE.json', 'utf8'))
const cohost = manifest?.cohost || {}
const requiredChecks = [
  'invite_accept',
  'dual_camera',
  'portrait_geometry',
  'audio_no_echo_or_whistle',
  'leave_cleanup',
]

assert.equal(cohost.status, 'passed', 'Release blocked: co-host physical acceptance is still pending.')
assert.match(cohost.tested_commit || '', /^[0-9a-f]{40}$/i, 'Release blocked: co-host tested_commit is missing or invalid.')
assert.match(cohost.fingerprint || '', /^[0-9a-f]{64}$/i, 'Release blocked: co-host acceptance fingerprint is missing or invalid.')
requiredChecks.forEach((name) => {
  assert.equal(cohost.checks?.[name], true, `Release blocked: physical co-host check "${name}" has not passed.`)
})

const currentFingerprint = fingerprint(criticalFiles)
assert.equal(
  cohost.fingerprint,
  currentFingerprint,
  'Release blocked: co-host code changed after the last physical acceptance. Re-test on two real devices.',
)

try {
  execFileSync('git', ['merge-base', '--is-ancestor', cohost.tested_commit, 'HEAD'], { stdio: 'ignore' })
} catch {
  assert.fail('Release blocked: physically tested co-host commit is not in this release history.')
}

console.log(`Release physical acceptance passed for co-host ${cohost.tested_commit.slice(0, 12)} with fingerprint ${currentFingerprint.slice(0, 12)}.`)
