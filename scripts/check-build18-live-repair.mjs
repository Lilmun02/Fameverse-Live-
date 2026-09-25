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
const codemagicPath = 'codemagic.yaml'

const [
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
  codemagic,
] = await Promise.all([
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
  load(codemagicPath),
])

requireText(stagePath, stage, 'class _V2CohostStage', 'approved co-host stage contract is missing')
requireText(stagePath, stage, 'aspectRatio: 1', 'co-host cameras must remain square')
requireText(stagePath, stage, 'class _V2CameraOffSurface', 'camera-off profile surface is missing')
requireText(stagePath, stage, 'participant.image?.trim()', 'camera-off must use the participant profile image when available')
forbidText(stagePath, stage, 'return Column(\n                children: [\n                  Expanded(\n                    child: _V2ParticipantSurface', 'do not restore stacked host/co-host portrait panels')

requireText(hostPath, host, 'image: widget.room.host.avatarUrl', 'host Stream identity must carry the profile photo for camera-off mode')
requireText(hostPath, host, 'widget.room.host.handle', 'host header must expose the creator handle')
requireText(hostPath, host, 'cohostCameraHeight + 32', 'host chat must sit directly below co-host cameras')
requireText(hostPath, host, 'FvLiveCommentComposer(', 'host must use the multiline Live composer')
requireText(hostPath, host, 'FvFameActionButton(', 'host must use the purple Fame action control')

requireText(viewerPath, viewer, "Key('viewer-gift-button')", 'tester-visible gift button contract is missing')
requireText(viewerPath, viewer, 'widget.room.host.handle', 'viewer live header must expose the creator handle')
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
requireText(sharedPath, shared, 'color: Color(0xFFB96BFF)', 'Fame F mark must remain purple')
requireText(giftPath, gift, 'playback.gift.cost <= 1', 'one-coin gifts must not use premium takeover overlay')
requireText(giftPath, gift, 'Future<int> Function() onRefill', 'open gift tray must receive fresh refill balance')
requireText(giftPath, gift, 'Navigator.of(context).pop();\n    await widget.onSend', 'gift tray must give immediate send feedback')
forbidText(visualPath, visual, 'ColoredBox(\n            color: Colors.black', 'gift tray black thumbnail boxes must not return')

requireText(rechargeScreenPath, rechargeScreen, "class NativeRechargeScreen", 'native PayPal sandbox recharge screen is missing')
requireText(rechargeScreenPath, rechargeScreen, "launchUrl(uri, mode: LaunchMode.externalApplication)", 'native recharge must open the real PayPal approval URL')
requireText(rechargeScreenPath, rechargeScreen, "'Complete sandbox purchase'", 'native recharge must provide an explicit PayPal capture step')
requireText(creatorStudioPath, creatorStudio, "if (_isOwner)", 'PayPal sandbox recharge must remain hidden from normal testers')
requireText(creatorStudioPath, creatorStudio, "NativeRechargeScreen", 'Creator Studio must route owner QA into native recharge')
requireText(rechargeSessionPath, rechargeSession, 'checkout: "native"', 'recharge session must identify native checkout')
requireText(rechargeSessionPath, rechargeSession, 'session: token', 'recharge session must return a secure native session token')
forbidText(rechargeSessionPath, rechargeSession, 'vercel.app', 'Vercel must not be part of the PayPal sandbox recharge flow')
requireText(rechargeApiPath, rechargeApi, 'approval_url: approvalUrl', 'PayPal create must return its approval URL to native Fameverse')
requireText(rechargeApiPath, rechargeApi, '"native-checkout-required"', 'direct browser GET must not silently restore an HTML checkout')
forbidText(rechargeApiPath, rechargeApi, 'vercel.app', 'Vercel must not be part of the PayPal sandbox recharge flow')
forbidText(rechargeApiPath, rechargeApi, 'text/html', 'Supabase recharge must remain an API rather than trying to serve HTML')

requireText(codemagicPath, codemagic, 'EXPECTED_BRANCH="build18/live-repair"', 'TestFlight must be hard-locked to the Build 18 branch')
requireText(codemagicPath, codemagic, 'build18_source_identity.txt', 'TestFlight must publish source identity evidence')
requireText(codemagicPath, codemagic, '--dart-define="FAMEVERSE_SOURCE_SHA=${CM_COMMIT}"', 'TestFlight must carry the exact source SHA at compile time')

if (failures.length) {
  console.error('Build 18 regression protection failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('DO NOT DISTRIBUTE BUILD 18.')
  process.exit(1)
}

console.log('Build 18 regression contracts are present. Physical iPhone owner + external tester QA is still required before PASS.')
