import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = (path) => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const source = read('codemagic.yaml')
const bootstrap = read('native/flutter_v1/tool/bootstrap_shorebird_android.sh')
const section = source.split('  shorebird-android-dry-run:\n')[1]?.split('  native-foundation:\n')[0] ?? ''

describe('Shorebird Android dry-run release candidate gate', () => {
  it('remains manual, pinned to isolated OTA source, and cannot publish', () => {
    expect(section).not.toBe('')
    expect(section).not.toMatch(/^\s+triggering:/m)
    expect(section).not.toMatch(/^\s+publishing:/m)
    expect(section).toContain('CM_TRIGGER_SOURCE:-')
    expect(section).toContain('chore/build48-shorebird-ota-readiness-nov15')
    expect(section).toContain('CM_COMMIT')
    expect(section).toContain('git rev-parse HEAD')
    expect(section).toContain('shorebird release android --dry-run --flutter-version=3.47.9')
    expect(section).not.toContain('shorebird patch ')
    expect(section).not.toContain('google_play:')
    expect(section).not.toContain('app_store_connect:')
    expect(section).not.toContain('artifacts:')
  })

  it('reuses an isolated deterministic native shell with the real Fameverse package', () => {
    expect(section).toContain('bash tool/bootstrap_shorebird_android.sh')
    expect(bootstrap).toContain('bash tool/verify_android_branding.sh')
    expect(section).toContain('dart run tool/check_native_contract.dart')
    expect(section).toContain('flutter analyze')
    expect(section).toContain('flutter test')
    expect(section).toContain('SHOREBIRD_TOKEN:-')
    expect(bootstrap).toContain('--org com.fameverse')
    expect(bootstrap).toContain('--project-name live')
    expect(bootstrap).toContain('com.fameverse.live')
    expect(bootstrap).toContain('bash tool/apply_android_branding.sh')
    expect(bootstrap).toContain('minSdk = 24')
    expect(bootstrap).not.toContain('shorebird release')
  })
})
