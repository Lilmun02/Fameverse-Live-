import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
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
  assert.match(script, /artifact\?\.source_commit/)
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

test('device status cannot substitute for explicit owner acceptance', () => {
  const dir = mkdtempSync(join(tmpdir(), 'build48-acceptance-'))
  try {
    mkdirSync(join(dir, 'docs'))
    writeFileSync(join(dir, 'gate.mjs'), script)
    const fixture = {
      ...manifest,
      status: 'passed',
      tested_commit: 'a'.repeat(40),
      fingerprint: 'b'.repeat(64),
      owner_acceptance: { status: 'pending' },
    }
    const run = () => {
      writeFileSync(join(dir, 'docs/BUILD48_NATIVE_PHYSICAL_ACCEPTANCE.json'),
        JSON.stringify(fixture))
      return spawnSync(process.execPath, ['gate.mjs'], { cwd: dir, encoding: 'utf8' })
    }
    const pending = run()
    assert.notEqual(pending.status, 0)
    assert.match(pending.stderr, /explicit owner acceptance is still pending/)
    fixture.owner_acceptance = { status: 'approved', source_commit: 'c'.repeat(40) }
    const mismatched = run()
    assert.notEqual(mismatched.status, 0)
    assert.match(mismatched.stderr, /owner accepted a different source commit/)
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
})

test('release gate rejects missing or mismatched platform artifact source', () => {
  const dir = mkdtempSync(join(tmpdir(), 'build48-artifacts-'))
  try {
    mkdirSync(join(dir, 'docs'))
    writeFileSync(join(dir, 'gate.mjs'), script)
    const commit = 'a'.repeat(40)
    const fixture = {
      ...manifest,
      status: 'passed',
      tested_commit: commit,
      fingerprint: 'b'.repeat(64),
      owner_acceptance: {
        status: 'approved', source_commit: commit,
        evidence_ref: 'synthetic-test-only', accepted_at: '2026-11-26',
      },
      artifacts: {
        ios: { build_id: 'fixture-ios', source_commit: commit },
        android: { build_id: 'fixture-android', source_commit: 'c'.repeat(40) },
      },
    }
    const run = () => {
      writeFileSync(join(dir, 'docs/BUILD48_NATIVE_PHYSICAL_ACCEPTANCE.json'),
        JSON.stringify(fixture))
      return spawnSync(process.execPath, ['gate.mjs'], { cwd: dir, encoding: 'utf8' })
    }
    const mismatch = run()
    assert.notEqual(mismatch.status, 0)
    assert.match(mismatch.stderr, /android artifact has different source/)
    delete fixture.artifacts.ios
    const missing = run()
    assert.notEqual(missing.status, 0)
    assert.match(missing.stderr, /ios build artifact ID is missing/)
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
})
