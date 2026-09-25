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
const viewerPath = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
const sharedPath = 'native/flutter_v1/lib/features/live/stream_live_shared.dart'
const giftPath = 'native/flutter_v1/lib/features/live/native_live_components.dart'
const visualPath = 'native/flutter_v1/lib/features/live/native_gift_visual.dart'

const [stage, viewer, shared, gift, visual] = await Promise.all([
  load(stagePath),
  load(viewerPath),
  load(sharedPath),
  load(giftPath),
  load(visualPath),
])

requireText(stagePath, stage, 'class _V2CohostStage', 'approved co-host stage contract is missing')
requireText(stagePath, stage, 'aspectRatio: 1', 'co-host cameras must remain square')
forbidText(stagePath, stage, 'return Column(\n                children: [\n                  Expanded(\n                    child: _V2ParticipantSurface', 'do not restore stacked host/co-host portrait panels')

requireText(viewerPath, viewer, "Key('viewer-gift-button')", 'tester-visible gift button contract is missing')
requireText(viewerPath, viewer, 'widget.room.host.handle', 'live header must expose the creator handle')
requireText(viewerPath, viewer, 'overflow: TextOverflow.fade', 'creator identity must not regress to ellipsis-only display')
requireText(viewerPath, viewer, 'state.endedAt != null || state.liveEndedAt != null', 'viewer must react when host ends the Stream call')
requireText(viewerPath, viewer, 'canPop: _leaving', 'leave flow must be able to release PopScope')
requireText(viewerPath, viewer, 'class _TapBurstParticle', 'visible F/flame tap feedback is missing')
forbidText(viewerPath, viewer, "fvGiftById('rose')", 'one-coin Rose shortcut must not crowd the tester action bar')

requireText(sharedPath, shared, 'fontSize: 14', 'physical QA chat readability floor is missing')
requireText(giftPath, gift, 'playback.gift.cost <= 1', 'one-coin gifts must not use premium takeover overlay')
requireText(giftPath, gift, 'Future<int> Function() onRefill', 'open gift tray must receive fresh refill balance')
requireText(giftPath, gift, 'Navigator.of(context).pop();\n    await widget.onSend', 'gift tray must give immediate send feedback')
forbidText(visualPath, visual, 'ColoredBox(\n            color: Colors.black', 'gift tray black thumbnail boxes must not return')

if (failures.length) {
  console.error('Build 18 live regression protection failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('DO NOT DISTRIBUTE BUILD 18.')
  process.exit(1)
}

console.log('Build 18 live regression contracts are present. Physical iPhone owner + external tester QA is still required before PASS.')
