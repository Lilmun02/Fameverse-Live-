import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

// Read-only Build 47 safety contract. The existing native-foundation
// workflow may run on this branch, but never signs or publishes an IPA.
const yaml = readFileSync(new URL('../../codemagic.yaml', import.meta.url), 'utf8')
const nativeTestFlight = yaml.split(/^  native-testflight:\s*$/m)[1]
const nativeFoundation = yaml.split(/^  native-foundation:\s*$/m)[1]?.split(/^  native-testflight:\s*$/m)[0]

describe('Build 47 existing TestFlight workflow regression contract', () => {
  it('runs Build 47 only in the existing non-publishing native preflight on pushes', () => {
    expect(nativeFoundation).toBeDefined()
    expect(nativeFoundation).toContain("pattern: 'native/flutter-v1'")
    expect(nativeFoundation).toContain("pattern: 'build47/backend-utc-rankings-nov05'")
    expect(nativeFoundation).toContain('cancel_previous_builds: true')
    expect(nativeFoundation).toContain('flutter analyze')
    expect(nativeFoundation).toContain('flutter test')
    expect(nativeFoundation).toContain('flutter build apk --debug')
    expect(nativeFoundation).toContain('flutter build ios --debug --no-codesign')
    expect(nativeFoundation).not.toContain('app_store_connect:')
    expect(nativeFoundation).not.toContain('publishing:')
    expect(nativeTestFlight).not.toMatch(/^    triggering:/m)
  })

  it('keeps the original workflow and distinct signed-IPA delivery path', () => {
    expect(yaml).toContain('  native-foundation:')
    expect(nativeTestFlight).toBeDefined()
    expect(nativeTestFlight).toContain('name: Fameverse Native TestFlight Candidate')
    expect(nativeTestFlight).toContain('BUNDLE_ID: "com.fameverse.live"')
    expect(nativeTestFlight).toContain('- appstore_credentials')
    expect(nativeTestFlight).toContain('- manual_signing')
    expect(nativeTestFlight).toContain('xcode-project use-profiles')
    expect(nativeTestFlight).toContain('flutter build ipa --release')
    expect(nativeTestFlight).toContain('app_store_connect:')
    expect(nativeTestFlight).toContain('api_key: $APP_STORE_CONNECT_PRIVATE_KEY')
    expect(nativeTestFlight).toContain('key_id: $APP_STORE_CONNECT_KEY_IDENTIFIER')
    expect(nativeTestFlight).toContain('issuer_id: $APP_STORE_CONNECT_ISSUER_ID')
    expect(nativeTestFlight).not.toMatch(/^    triggering:/m)
  })

  it('identifies Build 47 without falsely labeling an older family', () => {
    expect(nativeTestFlight).toContain('FAMEVERSE_BUILD_FAMILY: "47"')
    expect(nativeTestFlight).toContain('--dart-define="FAMEVERSE_BUILD_FAMILY=47"')
    expect(nativeTestFlight).toContain('build47_source_identity.txt')
    expect(nativeTestFlight).not.toContain('build32_source_identity.txt')
    expect(nativeTestFlight).not.toContain('FAMEVERSE_BUILD_FAMILY=32')
    expect(nativeTestFlight).toContain('git checkout --detach "$CM_COMMIT"')
    expect(nativeTestFlight).toContain('if [ "$SOURCE_SHA" != "$CM_COMMIT" ]; then')
    expect(nativeTestFlight).toContain('FAMEVERSE_SOURCE_SHA=$SOURCE_SHA')
  })

  it('fails closed when requested top-100 or UTC native ranking source is missing', () => {
    expect(nativeTestFlight).toContain('BLOCKED: native Fameboard is not requesting top 100.')
    expect(nativeTestFlight).toContain('BLOCKED: host End Live confirmation missing.')
    expect(nativeTestFlight).toContain('BLOCKED: native UTC daily ranking copy missing.')
    expect(nativeTestFlight).toContain('BLOCKED: native UTC weekly ranking copy missing.')
    expect(nativeTestFlight).toContain('BLOCKED: paired Build 47 UTC ranking SQL is absent.')
    expect(nativeTestFlight).toContain('This source check does NOT assert that the matching Supabase migration is deployed.')
    expect(nativeTestFlight).toContain('dart run tool/check_native_contract.dart')
    expect(nativeTestFlight).toContain('flutter analyze')
    expect(nativeTestFlight).toContain('flutter test')
  })

  it('retains the pre-existing purchasing-code guard without editing purchasing code', () => {
    expect(nativeTestFlight).toContain('STRIPE="../../supabase/functions/stripe-checkout-session/index.ts"')
    expect(nativeTestFlight).toContain('managed_payments[enabled]')
  })
})
