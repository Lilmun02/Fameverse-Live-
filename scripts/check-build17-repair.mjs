import { readFile } from 'node:fs/promises'

const failures = []

async function load(path) {
  return readFile(new URL(`../${path}`, import.meta.url), 'utf8')
}

function requireText(file, content, snippet, message) {
  if (!content.includes(snippet)) failures.push(`${file}: ${message}`)
}

function forbidText(file, content, snippet, message) {
  if (content.includes(snippet)) failures.push(`${file}: ${message}`)
}

const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_screen.dart'
const studioPath = 'native/flutter_v1/lib/features/profile/creator_studio_screen.dart'
const rechargeScreenPath = 'native/flutter_v1/lib/features/profile/native_recharge_screen.dart'
const payoutFixPath = 'supabase/migrations/20260924_fix_creator_payout_status_ambiguity.sql'
const rechargeSessionPath = 'supabase/functions/recharge-session/index.ts'
const rechargeApiPath = 'supabase/functions/recharge/index.ts'
const vitePath = 'vite.config.js'

const [
  profile,
  studio,
  rechargeScreen,
  payoutFix,
  rechargeSession,
  rechargeApi,
  vite,
] = await Promise.all([
  load(profilePath),
  load(studioPath),
  load(rechargeScreenPath),
  load(payoutFixPath),
  load(rechargeSessionPath),
  load(rechargeApiPath),
  load(vitePath),
])

// Profile law: public Profile stays social-first.
requireText(profilePath, profile, "Key('profile-display-name')", 'social display name contract is missing')
requireText(profilePath, profile, "Key('profile-bio')", 'social bio contract is missing')
requireText(profilePath, profile, "Key('edit-profile-button')", 'Edit profile contract is missing')
requireText(profilePath, profile, "Key('open-creator-studio')", 'Creator Studio entry contract is missing')
forbidText(profilePath, profile, 'Recharge Fame Coins', 'recharge must not render in the public profile')
forbidText(profilePath, profile, 'Signed in as', 'account email must not replace the social profile')

// Creator law: payout setup is separate from public account verification.
requireText(studioPath, studio, 'PAYOUT SETUP', 'creator payout setup section is missing')
requireText(studioPath, studio, 'separate from any public profile verification badge', 'payout/public-verification separation is missing')
forbidText(studioPath, studio, 'Request verification', 'vague one-tap verification must not return')
forbidText(studioPath, studio, '_OwnerPayoutSandboxQaScreen', 'old internal payout sandbox screen must not return')

// Owner PayPal QA is allowed only behind the owner role in Creator Studio.
requireText(studioPath, studio, 'if (_isOwner)', 'owner QA recharge must remain role-gated')
requireText(studioPath, studio, 'NativeRechargeScreen', 'Creator Studio must open the native PayPal recharge screen')
requireText(rechargeScreenPath, rechargeScreen, 'class NativeRechargeScreen', 'native PayPal recharge screen is missing')
requireText(rechargeScreenPath, rechargeScreen, 'LaunchMode.externalApplication', 'PayPal approval must open through the external PayPal/browser flow')
requireText(rechargeScreenPath, rechargeScreen, "'Complete sandbox purchase'", 'native PayPal capture step is missing')

// Database law: RETURNS TABLE output names must never be referenced ambiguously.
requireText(payoutFixPath, payoutFix, 'verification_request.status', 'verification status must be qualified')
requireText(payoutFixPath, payoutFix, 'ledger.amount_cents', 'earnings amount must be qualified')
requireText(payoutFixPath, payoutFix, 'payout.status', 'payout status must be qualified')

// Recharge law: Fameverse native UI + Supabase JSON API + PayPal only.
requireText(rechargeSessionPath, rechargeSession, 'checkout: "native"', 'recharge session must declare native checkout')
requireText(rechargeSessionPath, rechargeSession, 'session: token', 'recharge session must return the secure token')
requireText(rechargeApiPath, rechargeApi, 'approval_url: approvalUrl', 'PayPal create must return the PayPal approval URL')
requireText(rechargeApiPath, rechargeApi, '"native-checkout-required"', 'direct GET must refuse web checkout')
forbidText(rechargeSessionPath, rechargeSession, 'vercel.app', 'Vercel must not enter the recharge session path')
forbidText(rechargeApiPath, rechargeApi, 'vercel.app', 'Vercel must not enter the PayPal recharge API')
forbidText(rechargeApiPath, rechargeApi, 'text/html', 'Supabase recharge must remain JSON API-only')
forbidText(vitePath, vite, 'recharge.html', 'the web build must not publish a recharge checkout page')

if (failures.length) {
  console.error('Build 17/18 carried repair protection failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('DO NOT DISTRIBUTE THE NATIVE CANDIDATE.')
  process.exit(1)
}

console.log('Build 17/18 carried repair contracts passed: social profile, payout separation, SQL qualification, and native PayPal recharge are locked.')
