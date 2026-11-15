import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const script = readFileSync('scripts/check-native-physical-acceptance.mjs', 'utf8')
const manifest = JSON.parse(readFileSync('docs/BUILD48_NATIVE_PHYSICAL_ACCEPTANCE.json', 'utf8'))

test('the Build 48 gate requires two iPhones AND an Android device', () => {
  assert.equal(manifest.build, 48)
  for (const device of ['owner_iphone', 'external_tester_iphone', 'android_tester']) {
    assert.ok(manifest[device], `Missing device entry: ${device}`)
    assert.match(script, new RegExp(`verifyDevice\\(manifest\\.${device}`))
  }
  for (const platform of ['ios', 'android']) {
    assert.ok(manifest.artifacts[platform], `Missing artifact: ${platform}`)
  }
})

test('release guard binds real source and exact test artifacts', () => {
  assert.match(script, /manifest\.tested_commit/)
  assert.match(script, /manifest\.fingerprint/)
  assert.match(script, /currentFingerprint/)
  assert.match(script, /artifact\.source_commit/)
  assert.match(script, /device\.build_id/)
  assert.match(script, /'git', \['merge-base'/)
  assert.match(script, /battery_start_percent/)
  assert.match(script, /battery_end_percent/)
  assert.match(script, /thermal_observation/)
})

test('a pending physical manifest fails closed instead of claiming a release pass', () => {
  const result = spawnSync(process.execPath, ['scripts/check-native-physical-acceptance.mjs'], {
    encoding: 'utf8',
  })
  if (manifest.status === 'pending') {
    assert.notEqual(result.status, 0)
    assert.match(result.stderr, /physical acceptance is still pending on Android and iOS/)
  } else {
    assert.equal(result.status, 0, result.stderr)
  }
})
