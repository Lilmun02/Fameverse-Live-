import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const workflow = readFileSync(
  new URL('../../.github/workflows/build48-shorebird-android-binary-audit.yml', import.meta.url),
  'utf8',
)
const bootstrap = readFileSync(
  new URL('../../native/flutter_v1/tool/bootstrap_shorebird_android.sh', import.meta.url),
  'utf8',
)

describe('Build 48 Shorebird Android binary audit: test-only and real application ID', () => {
  it('only runs source-pinned checks on the isolated OTA branch', () => {
    expect(workflow).toContain('chore/build48-shorebird-ota-readiness-nov15')
    expect(workflow).toContain('test "$(git rev-parse HEAD)" = "$GITHUB_SHA"')
    expect(workflow).toContain('FAMEVERSE_OTA_STAGE: android-dry-run')
    expect(workflow).toContain("flutter-version: '3.47.9'")
    expect(workflow).toContain('bash tool/bootstrap_shorebird_android.sh')
  })

  it('compiles and inspects the actual Android binary without distribution', () => {
    expect(workflow).toContain('flutter build apk --debug')
    expect(workflow).toContain('aapt dump badging "$APK"')
    expect(workflow).toContain("package: name='com.fameverse.live'")
    expect(workflow).toContain('apksigner verify --print-certs "$APK"')
    expect(workflow).not.toContain('shorebird release android')
    expect(workflow).not.toContain('shorebird patch android')
    expect(workflow).not.toContain('upload-artifact')
    expect(workflow).not.toContain('publishing:')
    expect(workflow).not.toContain('secrets.')
    expect(workflow).toContain('permissions:\n  contents: read')
  })

  it('reuses the existing Android shell identity and branding safeguards', () => {
    expect(bootstrap).toContain('--org com.fameverse')
    expect(bootstrap).toContain('--project-name live')
    expect(bootstrap).toContain('applicationId = "com.fameverse.live"')
    expect(bootstrap).toContain('bash tool/verify_android_branding.sh')
  })
})
