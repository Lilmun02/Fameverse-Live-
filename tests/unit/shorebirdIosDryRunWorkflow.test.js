import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const yaml = read('codemagic.yaml')
const section = yaml.split('  shorebird-ios-dry-run:\n')[1]?.split(/^  [a-z0-9-]+:\n/m)[0] ?? ''
const bootstrap = read('native/flutter_v1/tool/bootstrap_shorebird_ios.sh')

describe('Shorebird iOS unsigned dry-run release gate', () => {
  it('must be manual, isolated, unsigned, and non-publishing', () => {
    expect(section).not.toBe('')
    expect(section).not.toMatch(/^\s+triggering:/m)
    expect(section).not.toMatch(/^\s+publishing:/m)
    expect(section).not.toMatch(/^\s+artifacts:/m)
    expect(section).toContain('CM_TRIGGER_SOURCE:-')
    expect(section).toContain('chore/build48-shorebird-ota-readiness-nov15')
    expect(section).toContain('git rev-parse HEAD')
    expect(section).toContain('CM_COMMIT')
    expect(section).toContain('SHOREBIRD_TOKEN:-')
    expect(section).toContain('shorebird release ios --dry-run --no-codesign --flutter-version=3.47.9')
    expect(section).not.toContain('shorebird patch ')
    expect(section).not.toContain('app_store_connect:')
    expect(section).not.toContain('manual_signing')
    expect(section).not.toContain('flutter build ipa')
  })

  it('must preserve locked iOS source identity, branding, and Flutter checks', () => {
    expect(section).toContain('xcode: 26.0')
    expect(section).toContain('bash tool/bootstrap_shorebird_ios.sh')
    expect(section).toContain('dart run tool/check_native_contract.dart')
    expect(section).toContain('flutter analyze')
    expect(section).toContain('flutter test')
    expect(bootstrap).toContain('--platforms=ios')
    expect(bootstrap).toContain('--org com.fameverse')
    expect(bootstrap).toContain('--project-name live')
    expect(bootstrap).toContain('com.fameverse.live')
    expect(bootstrap).toContain('git ls-files -- ios')
    expect(bootstrap).toContain('NSCameraUsageDescription')
    expect(bootstrap).toContain('NSMicrophoneUsageDescription')
    expect(bootstrap).toContain('bash tool/apply_ios_branding.sh')
    expect(bootstrap).toContain('bash tool/verify_ios_branding.sh')
    expect(bootstrap).not.toContain('shorebird release')
    expect(bootstrap).not.toContain('keychain')
  })
})
