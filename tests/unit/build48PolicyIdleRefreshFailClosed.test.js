import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const app = readFileSync(new URL('../../native/flutter_v1/lib/app/fameverse_app.dart', import.meta.url), 'utf8')
const policy = readFileSync(new URL('../../native/flutter_v1/lib/data/fv_policy_access.dart', import.meta.url), 'utf8')

describe('Build 48 idle policy refresh fail-closed routing', () => {
  it('does not reprompt a previously server-verified accepted account on a transient refresh failure', () => {
    expect(app).toContain('bool _acceptedBeforeRefreshFailure = false;')
    expect(app).toContain('final previouslyAccepted = _policyAccess?.hasAccepted == true;')
    expect(app).toContain('if (!refreshed.verifiedForAccount ||')
    expect(app).toContain('_policyAccess = _unavailablePolicy(identity.id);')
    expect(app).toContain('_acceptedBeforeRefreshFailure = true;')
    expect(app).toContain('_policyPromptDismissed = true;')
    expect(app).toContain('if (!policy.hasAccepted && !_policyPromptDismissed)')
  })

  it('does not retain old authorization and never elevates an unverifiable record', () => {
    expect(policy).toContain('decision == FvPolicyDecision.accepted')
    expect(policy).toContain('verifiedForAccount &&')
    expect(policy).toContain('case FvPolicyFeature.goLive:')
    expect(app).toContain('_unavailablePolicy(identity.id)')
    expect(app).not.toContain('_policyAccess = previousAccepted')
  })

  it('clears temporary dismissal when a valid fresh unsigned policy is received', () => {
    expect(app).toContain('if (_acceptedBeforeRefreshFailure) {')
    expect(app).toContain('_policyPromptDismissed = refreshed.decision == FvPolicyDecision.declined;')
    expect(app).toContain('_acceptedBeforeRefreshFailure = false;')
    expect(app).toContain('if (changedAccount) unawaited(_loadPolicyForIdentity(identity));')
  })
})
