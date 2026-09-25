import { readFile } from 'node:fs/promises'

const required = []
const forbidden = []

async function load(path) {
  return readFile(new URL(`../${path}`, import.meta.url), 'utf8')
}

function requireText(file, content, snippet, message) {
  if (!content.includes(snippet)) required.push(`${file}: ${message}`)
}

function forbidText(file, content, snippet, message) {
  if (content.includes(snippet)) forbidden.push(`${file}: ${message}`)
}

const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_screen.dart'
const studioPath = 'native/flutter_v1/lib/features/profile/creator_studio_screen.dart'
const payoutFixPath = 'supabase/migrations/20260924_fix_creator_payout_status_ambiguity.sql'
const rechargePagePath = 'recharge.html'
const rechargeApiPath = 'supabase/functions/recharge/index.ts'
const vitePath = 'vite.config.js'

const [profile, studio, payoutFix, rechargePage, rechargeApi, vite] = await Promise.all([
  load(profilePath),
  load(studioPath),
  load(payoutFixPath),
  load(rechargePagePath),
  load(rechargeApiPath),
  load(vitePath),
])

// Profile law: the public Profile tab is social identity first, not owner/admin QA.
requireText(profilePath, profile, "Key('profile-display-name')", 'social display name contract is missing')
requireText(profilePath, profile, "Key('profile-bio')", 'social bio contract is missing')
requireText(profilePath, profile, "Key('edit-profile-button')", 'Edit profile contract is missing')
requireText(profilePath, profile, "Key('open-creator-studio')", 'Creator Studio entry contract is missing')
forbidText(profilePath, profile, 'OWNER QA', 'owner QA must not render in the public profile')
forbidText(profilePath, profile, 'Recharge Fame Coins', 'recharge must not render in the public profile')
forbidText(profilePath, profile, 'Signed in as', 'account email must not replace the social profile')

// Creator law: payout eligibility is separate from public verification and owner moderation.
requireText(studioPath, studio, 'PAYOUT SETUP', 'creator payout setup section is missing')
requireText(studioPath, studio, 'separate from any public profile verification badge', 'payout/public-verification separation is missing')
forbidText(studioPath, studio, 'Request verification', 'vague one-tap verification must not return')
forbidText(studioPath, studio, 'OWNER QA', 'owner QA must not leak into Creator Studio')
forbidText(studioPath, studio, 'OWNER MODERATION', 'owner moderation must not leak into Creator Studio')
forbidText(studioPath, studio, '_OwnerPayoutSandboxQaScreen', 'internal payout sandbox UI must remain outside Creator Studio')

// Database law: RETURNS TABLE output names must never be referenced ambiguously.
requireText(payoutFixPath, payoutFix, 'verification_request.status', 'verification status must be qualified')
requireText(payoutFixPath, payoutFix, 'ledger.amount_cents', 'earnings amount must be qualified')
requireText(payoutFixPath, payoutFix, 'payout.status', 'payout status must be qualified')

// Recharge law: Supabase Edge Functions are API/redirect only; checkout HTML belongs to Vercel.
requireText(rechargePagePath, rechargePage, '<title>Fameverse Recharge</title>', 'hosted recharge page is missing')
requireText(vitePath, vite, "recharge: resolve(import.meta.dirname, 'recharge.html')", 'Vite must include the hosted recharge page')
requireText(rechargeApiPath, rechargeApi, 'redirectToCheckout', 'Edge recharge GET must redirect to the hosted checkout')
requireText(rechargeApiPath, rechargeApi, 'action === "config"', 'Edge recharge API must expose checkout configuration as JSON')
forbidText(rechargePagePath, rechargePage, 'Internal Build 16 purchase QA', 'stale Build 16 label must not return')
forbidText(rechargeApiPath, rechargeApi, 'Internal Build 16 purchase QA', 'Edge API must not contain stale Build 16 checkout copy')
forbidText(rechargeApiPath, rechargeApi, '"Content-Type": "text/html', 'Edge recharge must never attempt to serve HTML again')
forbidText(rechargeApiPath, rechargeApi, '<!doctype html>', 'checkout markup must never move back into the Edge Function')

if (required.length || forbidden.length) {
  console.error('Build 17 regression protection failed:')
  for (const failure of [...required, ...forbidden]) console.error(`- ${failure}`)
  console.error('Do not publish TestFlight until these regressions are repaired.')
  process.exit(1)
}

console.log('Build 17 regression protection passed: social profile, payout separation, payout SQL qualification, and hosted recharge contracts are locked.')
