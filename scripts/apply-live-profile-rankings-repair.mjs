import fs from 'node:fs'
import './apply-build32-rankings.mjs'

function read(path) {
  return fs.readFileSync(path, 'utf8')
}

const host = read('native/flutter_v1/lib/features/live/stream_host_live_screen.dart')
const viewer = read('native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart')
const rankings = read('native/flutter_v1/lib/features/live/native_live_rankings.dart')
const discover = read('native/flutter_v1/lib/features/shell/fameverse_discover_screen.dart')

for (const [label, source, markers] of [
  ['host', host, ['showNativeLiveProfileSheet', "Key('host-live-rankings-left')", 'showNativeLiveRankings']],
  ['viewer', viewer, ['showNativeLiveProfileSheet', "Key('viewer-live-rankings-button')", 'showNativeLiveRankings']],
  ['Fameboard', rankings, ["'get_fameverse_rankings_v2'", "('supporters', 'Supporters'", "('pulse', 'Pulse'", "('24h', '24H')", "('7d', '7D')"]],
  ['Discover', discover, ["Key('discover-fameboard-card')", 'showNativeLiveRankings(context)']],
]) {
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`[live-profile-rankings] ${label} contract missing: ${marker}`)
    }
  }
}

console.log('Verified native Live profile and Build 32 Fameboard wiring.')
