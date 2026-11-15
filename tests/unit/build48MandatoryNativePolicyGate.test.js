import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const app = read('native/flutter_v1/lib/app/fameverse_app.dart')
const consent = read('native/flutter_v1/lib/features/profile/fameverse_policy_consent_screen.dart')
const access = read('native/flutter_v1/lib/data/fv_policy_access.dart')
const inbox = read('native/flutter_v1/lib/features/profile/fameverse_inbox_screen.dart')

describe('Build 48 native policy choice is mandatory', () => {
  it('requires explicit acceptance or decline and has no continue/browse escape', () => {
    expect(app).toContain('if (!policy.hasAccepted && !_policyPromptDismissed)')
    expect(app).toContain('onAccept: () => unawaited(_submitPolicyDecision(accept: true))')
    expect(app).toContain('onDecline: () => unawaited(_submitPolicyDecision(accept: false))')
    expect(app).not.toContain('onBrowseRestricted')
    expect(consent).not.toContain('onBrowseRestricted')
    expect(consent).not.toContain('build47-limited-browsing')
    expect(consent).toContain('build47-policy-checkbox')
    expect(consent).toContain('_readAndAgree &&')
  })

  it('decline bypasses only the consent screen once server-verified', () => {
    expect(app).toContain('access.verifiedForAccount &&')
    expect(app).toContain('access.decision == FvPolicyDecision.declined')
    expect(app).toContain('_policyPromptDismissed = !accept;')
    expect(app).toContain('if (verified.accountId != identity.id)')
    expect(inbox).toContain('policy?.decision == FvPolicyDecision.declined')
    expect(inbox).toContain("Key('inbox-policy-review')")
  })

  it('notice/grace preserves deadlines but never grants restricted features while unsigned', () => {
    expect(access).toContain('bool get canUseRestrictedFeatures => hasAccepted;')
    expect(access).toContain('case FvPolicyFeature.goLive:')
    expect(access).toContain('case FvPolicyFeature.purchaseCoins:')
    expect(access).toContain('case FvPolicyFeature.betaBadges:')
    expect(access).toContain('case FvPolicyFeature.bringYourBadge:')
    expect(consent).toContain('7-day notice and 3-day grace period')
  })
})
