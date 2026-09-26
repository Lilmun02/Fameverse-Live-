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

const appPath = 'native/flutter_v1/lib/app/fameverse_app.dart'
const authPath = 'native/flutter_v1/lib/features/auth/auth_screen.dart'
const profilePath = 'native/flutter_v1/lib/features/profile/native_profile_screen.dart'
const stagePath = 'native/flutter_v1/lib/features/live/native_live_stage.dart'
const hostPath = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
const viewerPath = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
const sharedPath = 'native/flutter_v1/lib/features/live/stream_live_shared.dart'
const giftPath = 'native/flutter_v1/lib/features/live/native_live_components.dart'
const visualPath = 'native/flutter_v1/lib/features/live/native_gift_visual.dart'
const rechargeScreenPath = 'native/flutter_v1/lib/features/profile/native_recharge_screen.dart'
const creatorStudioPath = 'native/flutter_v1/lib/features/profile/creator_studio_screen.dart'
const rechargeSessionPath = 'supabase/functions/recharge-session/index.ts'
const rechargeApiPath = 'supabase/functions/recharge/index.ts'
const rechargePricingPath = 'supabase/migrations/20260926_owner_qa_coin_pricing_v2.sql'
const retireNoticePath = 'supabase/migrations/20260926_retire_build16_startup_notice.sql'
const codemagicPath = 'codemagic.yaml'

const [
  app,
  auth,
  profile,
  stage,
  host,
  viewer,
  shared,
  gift,
  visual,
  rechargeScreen,
  creatorStudio,
  rechargeSession,
  rechargeApi,
  rechargePricing,
  retireNotice,
  codemagic,
] = await Promise.all([
  load(appPath),
  load(authPath),
  load(profilePath),
  load(stagePath),
  load(hostPath),
  load(viewerPath),
  load(sharedPath),
  load(giftPath),
  load(visualPath),
  load(rechargeScreenPath),
  load(creatorStudioPath),
  load(rechargeSessionPath),
  load(rechargeApiPath),
  load(rechargePricingPath),
  load(retireNoticePath),
  load(codemagicPath),
])

// Startup law: one branded splash is allowed. Stale backend/update theater is not.
requireText(appPath, app, "Key('fameverse-native-splash')", 'native brand splash contract is missing')
forbidText(appPath, app, 'startup_update_service.dart', 'startup must not replay backend notices on every launch')
forbidText(appPath, app, 'Checking for updates', 'candidate must not display a fake/repeated update-check phase')
forbidText(appPath, app, 'Syncing Fameverse services', 'candidate must not display repeated backend sync theater')
requireText(retireNoticePath, retireNotice, 'set active = false', 'stale Build 16 update notice must be retired')
requireText(retireNoticePath, retireNotice, 'build_number = 16', 'Build 16 retirement must target the stale notice explicitly')

// Authentication law: existing users must land on Sign in by default and never
// be silently redirected into account creation.
requireText(authPath, auth, '_AuthMode _mode = _AuthMode.signIn', 'existing-account sign in must be the default auth mode')
requireText(authPath, auth, "Key('auth-mode-sign-in')", 'explicit Sign in selector is missing')
requireText(authPath, auth, "Key('auth-mode-sign-up')", 'explicit Create account selector is missing')
requireText(authPath, auth, 'await widget.backend.signIn(email: email, password: password)', 'existing-account submit must call signIn')
requireText(authPath, auth, 'That email already has a Fameverse account. Sign in instead.', 'registered signup attempts must return users to sign in')

// Profile law: social identity only. No admin dashboard or QA/payment leakage.
requireText(profilePath, profile, "Key('profile-cover')", 'social profile cover is missing')
requireText(profilePath, profile, "Key('profile-display-name')", 'social display name is missing')
requireText(profilePath, profile, "Key('profile-handle')", 'social handle is missing')
requireText(profilePath, profile, "Key('profile-bio')", 'social bio is missing')
requireText(profilePath, profile, "Key('profile-social-stats')", 'social follower/following/friend stats are missing')
requireText(profilePath, profile, "Key('edit-profile-button')", 'Edit profile action is missing')
requireText(profilePath, profile, "Key('open-creator-studio')", 'Creator Studio entry is missing')
forbidText(profilePath, profile, 'OWNER QA', 'owner QA must never render on the public profile')
forbidText(profilePath, profile, 'Recharge Fame Coins', 'recharge must never render on the public profile')
forbidText(profilePath, profile, 'Signed in as', 'account email must never replace social identity')
forbidText(profilePath, profile, 'Admin - Owner', 'role/debug identity must never render as profile content')

// V2 Live law: solo is the approved Neon Infamous full-camera composition;
// co-host remains exactly two equal square cameras side-by-side.
requireText(stagePath, stage, 'class _V2CohostStage', 'approved co-host stage contract is missing')
requireText(stagePath, stage, 'aspectRatio: 1', 'co-host cameras must remain square')
requireText(stagePath, stage, 'class _V2CameraOffSurface', 'camera-off profile surface is missing')
requireText(stagePath, stage, 'participant.image?.trim()', 'camera-off must use the participant profile image when available')
forbidText(stagePath, stage, 'return Column(\n                children: [\n                  Expanded(\n                    child: _V2ParticipantSurface', 'do not restore stacked host/co-host portrait panels')

requireText(hostPath, host, 'image: widget.room.host.avatarUrl', 'host Stream identity must carry the profile photo for camera-off mode')
requireText(hostPath, host, "Key('host-v2-fameverse-wordmark')", 'approved solo Live Fameverse wordmark is missing')
requireText(hostPath, host, "'PEOPLE MAKE LEGENDS'", 'approved solo Live brand line is missing')
requireText(hostPath, host, 'widget.room.host.displayName', 'solo Live must show the creator display name rather than a role/debug handle')
requireText(hostPath, host, 'class _NeonHostAvatar', 'approved neon creator avatar is missing')
requireText(hostPath, host, 'class _LiveStatsPill', 'viewer and Fame stats must remain one compact V2 pill')
requireText(hostPath, host, "Key('host-v2-combined-stats')", 'combined V2 stats key is missing')
requireText(hostPath, host, 'backgroundColor: const Color(0xFFE62952)', 'host End action must stay red')
requireText(hostPath, host, 'cohostCameraHeight + 32', 'host chat must sit directly below co-host cameras')
requireText(hostPath, host, 'FvLiveCommentComposer(', 'host must use the multiline Live composer')
requireText(hostPath, host, 'FvFameActionButton(', 'host must use the purple Fame action control')

requireText(viewerPath, viewer, "Key('viewer-gift-button')", 'tester-visible gift button contract is missing')
requireText(viewerPath, viewer, 'widget.room.host.handle', 'viewer live header must expose the creator identity')
requireText(viewerPath, viewer, 'state.endedAt != null || state.liveEndedAt != null', 'viewer must react when host ends the Stream call')
requireText(viewerPath, viewer, 'canPop: _leaving', 'leave flow must be able to release PopScope')
requireText(viewerPath, viewer, 'class _TapBurstParticle', 'visible F/flame tap feedback is missing')
requireText(viewerPath, viewer, 'cohostCameraHeight + 32', 'viewer chat must sit directly below co-host cameras')
requireText(viewerPath, viewer, 'FvLiveCommentComposer(', 'viewer must use the multiline Live composer')
requireText(viewerPath, viewer, 'FvFameActionButton(', 'viewer must use the purple Fame action control')
forbidText(viewerPath, viewer, "fvGiftById('rose')", 'one-coin Rose shortcut must not crowd the tester action bar')

requireText(sharedPath, shared, 'fontSize: 15', 'physical QA chat readability floor is missing')
requireText(sharedPath, shared, 'maxLines: 3', 'Live composer must wrap to multiple visible lines')
requireText(sharedPath, shared, 'keyboardType: TextInputType.multiline', 'Live composer must accept multiline typing')
requireText(sharedPath, shared, 'color: Color(0xFFE1B5FF)', 'Fame F mark must remain purple')
requireText(sharedPath, shared, "Key('v2-highlighted-gift-chat')", 'gift activity must keep the approved highlighted V2 chat treatment')
requireText(sharedPath, shared, ': null,', 'ordinary comments must remain lightweight instead of large cards')
requireText(giftPath, gift, 'playback.gift.cost <= 1', 'one-coin gifts must not use premium takeover overlay')
requireText(giftPath, gift, 'Future<int> Function() onRefill', 'open gift tray must receive fresh refill balance')
requireText(giftPath, gift, 'Navigator.of(context).pop();\n    await widget.onSend', 'gift tray must give immediate send feedback')
forbidText(visualPath, visual, 'ColoredBox(\n            color: Colors.black', 'gift tray black thumbnail boxes must not return')

// PayPal recharge law: native UI + Supabase API + PayPal. Custom amounts are
// server-authoritative and bounded; Vercel/HTML must never return.
requireText(rechargeScreenPath, rechargeScreen, 'class NativeRechargeScreen', 'native PayPal sandbox recharge screen is missing')
requireText(rechargeScreenPath, rechargeScreen, 'final launched = await launchUrl(', 'native recharge must open the PayPal approval URL')
requireText(rechargeScreenPath, rechargeScreen, 'mode: LaunchMode.externalApplication', 'PayPal approval must leave the app through the external browser/application')
requireText(rechargeScreenPath, rechargeScreen, "Key('custom-fame-coins-card')", 'native recharge must expose the custom amount choice')
requireText(rechargeScreenPath, rechargeScreen, "'custom_coins': coins", 'native custom amount must be sent to the secure recharge API')
requireText(rechargeScreenPath, rechargeScreen, "'Complete sandbox purchase'", 'native recharge must provide an explicit PayPal capture step')
requireText(creatorStudioPath, creatorStudio, 'if (_isOwner)', 'PayPal sandbox recharge must remain hidden from normal testers')
requireText(creatorStudioPath, creatorStudio, 'NativeRechargeScreen', 'Creator Studio must route owner QA into native recharge')
requireText(rechargeSessionPath, rechargeSession, 'checkout: "native"', 'recharge session must identify native checkout')
requireText(rechargeSessionPath, rechargeSession, 'session: token', 'recharge session must return a secure native session token')
forbidText(rechargeSessionPath, rechargeSession, 'vercel.app', 'Vercel must not be part of the PayPal sandbox recharge flow')
requireText(rechargeApiPath, rechargeApi, 'CUSTOM_PACK_ID = "owner-qa-custom"', 'custom recharge pack contract is missing')
requireText(rechargeApiPath, rechargeApi, 'CUSTOM_MIN_COINS = 100', 'custom recharge lower bound is missing')
requireText(rechargeApiPath, rechargeApi, 'CUSTOM_MAX_COINS = 10000', 'custom recharge upper bound is missing')
requireText(rechargeApiPath, rechargeApi, 'customCoins * CUSTOM_CENTS_PER_COIN', 'custom recharge price must be calculated server-side')
requireText(rechargeApiPath, rechargeApi, 'approval_url: approvalUrl', 'PayPal create must return its approval URL to native Fameverse')
requireText(rechargeApiPath, rechargeApi, '"native-checkout-required"', 'direct browser GET must not silently restore an HTML checkout')
forbidText(rechargeApiPath, rechargeApi, 'vercel.app', 'Vercel must not be part of the PayPal sandbox recharge flow')
forbidText(rechargeApiPath, rechargeApi, 'text/html', 'Supabase recharge must remain an API rather than trying to serve HTML')
requireText(rechargePricingPath, rechargePricing, "('owner-qa-100', '100 Fame Coins', 100, 99", 'reasonable 100-coin sandbox pack is missing')
requireText(rechargePricingPath, rechargePricing, "('owner-qa-5000', '5,000 Fame Coins', 5000, 4999", 'reasonable 5000-coin sandbox pack is missing')
requireText(rechargePricingPath, rechargePricing, "('owner-qa-custom', 'Custom Fame Coins'", 'custom recharge placeholder pack is missing')

// Source identity law. A Codemagic trigger may originate from the base branch,
// but the publishing workflow must fetch and detach-checkout the locked repair
// branch, record the resulting SHA, and compile that exact SHA into the IPA.
requireText(codemagicPath, codemagic, 'TARGET_BRANCH="build18/live-repair"', 'TestFlight must target the locked repair branch')
requireText(codemagicPath, codemagic, 'git checkout --detach "refs/remotes/origin/$TARGET_BRANCH"', 'TestFlight must checkout the locked repair branch before validation/build')
requireText(codemagicPath, codemagic, 'FAMEVERSE_SOURCE_SHA=$SOURCE_SHA', 'TestFlight must persist the exact locked repair SHA')
requireText(codemagicPath, codemagic, 'build18_source_identity.txt', 'TestFlight must publish source identity evidence')
requireText(codemagicPath, codemagic, '--dart-define="FAMEVERSE_SOURCE_SHA=${FAMEVERSE_SOURCE_SHA}"', 'TestFlight must compile the exact locked repair SHA into the candidate')

if (failures.length) {
  console.error('Build 18 regression protection failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('DO NOT DISTRIBUTE THE NEXT TESTFLIGHT CANDIDATE.')
  process.exit(1)
}

console.log('Build 18 regression contracts are present. Physical iPhone owner + external tester QA is still required before PASS.')
