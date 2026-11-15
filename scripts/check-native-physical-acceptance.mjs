import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

// Build 48 device acceptance is a release gate, not an unsigned-compile gate.
// Keep Build 18 evidence archived separately; never inherit its test results.
const manifest = JSON.parse(readFileSync('docs/BUILD48_NATIVE_PHYSICAL_ACCEPTANCE.json', 'utf8'))
const criticalFiles = [
  'codemagic.yaml',
  'native/flutter_v1/pubspec.yaml',
  'native/flutter_v1/lib/features/live/native_live_stage.dart',
  'native/flutter_v1/lib/features/live/stream_host_live_screen.dart',
  'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart',
  'native/flutter_v1/lib/features/live/native_live_components.dart',
  'native/flutter_v1/lib/features/live/native_gift_visual.dart',
  'native/flutter_v1/lib/features/live/stream_live_shared.dart',
  'native/flutter_v1/lib/data/fameverse_live_backend.dart',
  'native/flutter_v1/lib/features/shell/fameverse_shell_build23.dart',
  'native/flutter_v1/lib/features/profile/native_profile_build23.dart',
]
const requiredChecks = [
  'live_video_audio_stable',
  'cohost_invite_accept_and_leave',
  'camera_switch_and_mic',
  'gifts_play_once_with_audio',
  'background_and_foreground_recovery',
  'tap_chat_and_feed_responsive',
  'battery_and_thermal_review',
]

function fingerprint(paths) {
  const hash = createHash('sha256')
  for (const path of paths) {
    hash.update(path)
    hash.update('\0')
    hash.update(readFileSync(path))
    hash.update('\0')
  }
  return hash.digest('hex')
}

function requireText(value, label) {
  assert.ok(typeof value === 'string' && value.trim().length > 0,
    `Release blocked: ${label} is missing.`)
}

function verifyDevice(device, label, artifact) {
  assert.equal(device?.status, 'passed',
    `Release blocked: ${label} physical acceptance is still pending.`)
  for (const field of ['device_model', 'os_version', 'build_id', 'tested_at', 'evidence_ref',
    'thermal_observation']) {
    requireText(device[field], `${label} ${field}`)
  }
  assert.equal(device.source_commit, manifest.tested_commit,
    `Release blocked: ${label} used a different source commit.`)
  assert.equal(device.build_id, artifact.build_id,
    `Release blocked: ${label} tested a different build artifact.`)
  assert.ok(Number.isFinite(device.session_minutes) && device.session_minutes >= 15,
    `Release blocked: ${label} needs at least 15 minutes of Live QA.`)
  for (const field of ['battery_start_percent', 'battery_end_percent']) {
    assert.ok(Number.isFinite(device[field]) && device[field] >= 0 && device[field] <= 100,
      `Release blocked: ${label} ${field} must be a recorded battery percentage.`)
  }
  for (const check of requiredChecks) {
    assert.equal(device.checks?.[check], true,
      `Release blocked: ${label} check ${check} has not passed.`)
  }
}

assert.equal(manifest.build, 48, 'Release blocked: acceptance manifest must be Build 48.')
assert.equal(manifest.status, 'passed',
  'Release blocked: Build 48 physical acceptance is still pending on Android and iOS.')
assert.match(manifest.tested_commit || '', /^[0-9a-f]{40}$/i,
  'Release blocked: exact physically tested source commit missing.')
assert.match(manifest.fingerprint || '', /^[0-9a-f]{64}$/i,
  'Release blocked: device acceptance source fingerprint missing.')

for (const platform of ['ios', 'android']) {
  const artifact = manifest.artifacts?.[platform]
  requireText(artifact?.build_id, `${platform} build artifact ID`)
  assert.equal(artifact?.source_commit, manifest.tested_commit,
    `Release blocked: ${platform} artifact has different source.`)
}

verifyDevice(manifest.owner_iphone, 'owner iPhone', manifest.artifacts.ios)
verifyDevice(manifest.external_tester_iphone, 'external tester iPhone', manifest.artifacts.ios)
verifyDevice(manifest.android_tester, 'Android tester', manifest.artifacts.android)

const currentFingerprint = fingerprint(criticalFiles)
assert.equal(manifest.fingerprint, currentFingerprint,
  'Release blocked: native code or signing changed since device QA. Re-test Android and iOS.')

try {
  execFileSync('git', ['merge-base', '--is-ancestor', manifest.tested_commit, 'HEAD'],
    { stdio: 'ignore' })
} catch {
  assert.fail('Release blocked: the physically tested source is not in this branch history.')
}

console.log(
  `Build 48 Android + iPhone physical gate passed at ${manifest.tested_commit.slice(0, 12)} ` +
  `with fingerprint ${currentFingerprint.slice(0, 12)}.`,
)
