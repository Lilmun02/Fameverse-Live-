import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const file = path =>
  readFileSync(new URL('../../' + path, import.meta.url), 'utf8')

const app = file('native/flutter_v1/lib/app/fameverse_app.dart')
const shell = file('native/flutter_v1/lib/features/shell/fameverse_shell_build23.dart')
const settings = file('native/flutter_v1/lib/features/profile/native_profile_build23.dart')
const policy = file('native/flutter_v1/lib/data/fv_policy_access.dart')
const service = file('native/flutter_v1/lib/data/fv_policy_acceptance_service.dart')
const consent = file('native/flutter_v1/lib/features/profile/fameverse_policy_consent_screen.dart')
const migration = file('supabase/migrations/20261105220000_policy_acceptances_review_only.sql')

describe('Build 47 policy update source safety contract', () => {
  it('prompts signed-in users after the normal splash/update notice', () => {
    const notice = app.indexOf('if (notice != null && !_noticeAcknowledged)')
    const identity = app.indexOf('final identity = _identity;', app.indexOf('Widget _buildStartupRoute()'))
    const gate = app.indexOf('if (!policy.hasAccepted && !_policyPromptDismissed)')
    expect(notice).toBeGreaterThan(-1)
    expect(identity).toBeGreaterThan(notice)
    expect(gate).toBeGreaterThan(identity)
    expect(app).toContain('FameversePolicyConsentScreen(')
    expect(app).toContain('onAccept: () => unawaited(_submitPolicyDecision(accept: true))')
    expect(app).toContain('onDecline: () => unawaited(_submitPolicyDecision(accept: false))')
    expect(app).toContain('if (changedAccount) unawaited(_loadPolicyForIdentity(identity));')
  })

  it('requires deliberate consent and offers full terms and restricted browsing', () => {
    expect(consent).toContain("Key('build47-policy-checkbox')")
    expect(consent).toContain('_readAndAgree && !widget.busy')
    expect(consent).toContain("Key('build47-read-full-policy')")
    expect(consent).toContain('FameversePolicyScreen()')
    expect(consent).toContain("Key('build47-accept-policy')")
    expect(consent).toContain("Key('build47-decline-policy')")
    expect(consent).toContain("Key('build47-limited-browsing')")
    expect(consent).toContain('A failed save never counts as acceptance.')
  })

  it('only trusts server-verified account-bound acceptance', () => {
    expect(policy).toContain('verifiedForAccount &&')
    expect(policy).toContain('decision == FvPolicyDecision.accepted')
    expect(service).toContain('client.auth.currentUser')
    expect(service).toContain(".from('policy_acceptances').upsert({")
    expect(service).toContain("onConflict: 'user_id,policy_version'")
    expect(service).toContain('final verified = await loadCurrent()')
    expect(service).toContain('verifiedForAccount: matched')
    expect(service).toContain('FvPolicyDecision.unavailable')
    expect(app).toContain('final policy = _policyAccess ?? _unavailablePolicy(identity.id)')
  })

  it('restricts Live and beta badge entry without denying basic browsing', () => {
    expect(policy).toContain('case FvPolicyFeature.watchLive:')
    expect(policy).toContain('case FvPolicyFeature.viewProfiles:')
    expect(policy).toContain('case FvPolicyFeature.search:')
    expect(policy).toContain('case FvPolicyFeature.inbox:')
    expect(policy).toContain('case FvPolicyFeature.support:')
    expect(policy).toContain('case FvPolicyFeature.goLive:')
    expect(policy).toContain('case FvPolicyFeature.purchaseCoins:')
    expect(policy).toContain('case FvPolicyFeature.betaBadges:')
    expect(shell).toContain('if (_canGoLive)')
    expect(shell).toContain('Live hosting requires policy acceptance.')
    expect(shell).toContain('_canUseBetaBadges && !_isOwner && _betaStatus.enrolled')
    expect(settings).toContain('if (!isOwner && onFirstVerse != null) ...[')
    expect(settings).toContain("key: const Key('settings-owner-premium-card')")
  })

  it('locks original notice timestamp, grace, expiry and server-scoped rights', () => {
    expect(service).toContain('ignoreDuplicates: true')
    expect(service).toContain('get_my_fameverse_policy_status')
    expect(service).toContain('can_use_restricted')
    expect(service).toContain('requires_support')
    expect(service).toContain('grace_starts_at')
    expect(policy).toContain('withinNoticeWindow')
    expect(policy).toContain('bool get canUseRestrictedFeatures => hasAccepted || hasTemporaryAccess')
    expect(consent).toContain('You are in the 3-day grace period.')
    expect(consent).toContain('Fameverse support Monday–Friday.')
    expect(consent).toContain("Key('build47-policy-deadline-message')")
  })

  it('locks RLS and account ownership for the 10-day migration', () => {
    expect(migration).toContain("interval '7 days'")
    expect(migration).toContain("interval '10 days'")
    expect(migration).toContain('get_my_fameverse_policy_status')
    expect(migration).toContain('security invoker')
    expect(migration).toContain('new.notice_started_at := old.notice_started_at')
    expect(migration).toContain('enable row level security')
    expect(migration).toContain('revoke all on public.policy_acceptances from public, anon, authenticated')
    expect(migration).toContain('with check ((select auth.uid()) = user_id)')
    expect(migration).toContain('using ((select auth.uid()) = user_id)')
    expect(migration).toContain('existing Live/Stripe server entrypoints are')
  })
})
