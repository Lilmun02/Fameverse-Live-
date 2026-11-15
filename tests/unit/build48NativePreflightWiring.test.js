import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const cm = read('codemagic.yaml')
const gh = read('.github/workflows/native-preflight.yml')

describe('Build 48 native CI wiring regression', () => {
  it('runs existing unsigned Codemagic foundation for Build 48', () => {
    const foundation = cm.split('  native-foundation:')[1]?.split('  native-testflight:')[0]
    expect(foundation).toContain("pattern: 'build48/performance-live-stability-android-ios-nov15'")
    expect(foundation).toContain('flutter build apk --debug')
    expect(foundation).toContain('flutter build ios --debug --no-codesign')
    expect(foundation).not.toContain('app_store_connect:')
  })

  it('runs Flutter analysis, widget tests and both platform preflights on Build 48 PRs', () => {
    expect(gh).toContain('build48/performance-live-stability-android-ios-nov15')
    expect(gh).toContain("'fix/build48-*'")
    expect(gh).toContain('dart format --output=none --set-exit-if-changed')
    expect(gh).toContain('flutter analyze')
    expect(gh).toContain('flutter test')
    expect(gh).toContain('flutter build apk --debug')
    expect(gh).toContain('actions/upload-artifact@v4')
    expect(gh).toContain('native/flutter_v1/build/app/outputs/flutter-apk/app-debug.apk')
    expect(gh).toContain('physical-release-gate:')
    expect(gh).toContain('node scripts/check-native-physical-acceptance.mjs')
  })
})
