import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const read = path => readFileSync(new URL('../../' + path, import.meta.url), 'utf8')
const app = read('native/flutter_v1/lib/app/fameverse_app.dart')
const policy = read('native/flutter_v1/lib/data/fv_policy_access.dart')
const reducer = read('native/flutter_v1/lib/data/fv_policy_refresh.dart')
const flutterTests = read('native/flutter_v1/test/fv_policy_refresh_test.dart')

// Source integration checks only. Real behavior is tested by Flutter tests
// in native/flutter_v1/test/fv_policy_refresh_test.dart.
describe('Build 48 idle policy refresh: native test integration contract', () => {
  it('calls the reconciler rather than writing a possibly stale access decision directly', () => {
    expect(app).toContain("import '../data/fv_policy_refresh.dart';")
    expect(app).toContain('final next = reconcilePolicyRefresh(')
    expect(app).toContain('_policyAccess = next.access;')
    expect(app).toContain('_policyPromptDismissed = next.promptDismissed;')
    expect(app).toContain('_acceptedBeforeRefreshFailure = next.acceptedBeforeRefreshFailure;')
    expect(app).toContain('request != _policyRefreshRequest ||')
    expect(app).toContain('++_policyRefreshRequest;')
    expect(app).toContain('if (!policy.hasAccepted && !_policyPromptDismissed)')
  })

  it('requires a verified account-and-version matched refresh to regain rights', () => {
    expect(reducer).toContain('incoming.verifiedForAccount')
    expect(reducer).toContain('incoming.accountId == accountId')
    expect(reducer).toContain('incoming.policyVersion == policyVersion')
    expect(reducer).toContain('FvPolicyDecision.unavailable')
    expect(reducer).toContain('current.access.hasAccepted')
    expect(policy).toContain('decision == FvPolicyDecision.accepted')
    expect(policy).toContain('verifiedForAccount &&')
  })

  it('ships executable Flutter scenarios; Javascript contract checks alone are insufficient', () => {
    for (const scenario of [
      'offline refresh retains browsing but immediately revokes permissions',
      'repeated offline refresh cannot re-prompt or restore access',
      'fresh verified acceptance restores permissions without another prompt',
      'verified revoked/unsigned result reopens the agreement',
      'verified decline stays in limited browsing without claiming consent',
      'unverified accounts are never treated as previously accepted',
      'wrong-account and wrong-policy-version responses fail closed',
      'accepted status from another identity never establishes dismissal',
      'support-required response keeps the policy gate visible',
    ]) {
      expect(flutterTests).toContain(scenario)
    }
  })
})
