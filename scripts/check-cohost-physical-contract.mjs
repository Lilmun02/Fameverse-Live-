import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const hostHook = read('src/hooks/useCohostHost.js')
const viewerHook = read('src/hooks/useCohostViewer.js')
const viewerScreen = read('src/components/live/ViewerLiveScreen.jsx')
const tile = read('src/components/live/CohostVideoTile.jsx')
const peer = read('src/services/live/webrtcPeer.js')
const css = read('src/styles/live/cohost.css')

assert.match(css, /--fv-cohost-pane-height:\s*min\(88\.8889vw,\s*52dvh,\s*460px\)/, 'Co-host panes must use Safari-safe height-bounded portrait dimensions.')
assert.doesNotMatch(css, /--fv-cohost-pane-height:[^;]*(?:\*|\/\s*9)/, 'Co-host pane height must not rely on unsupported CSS multiplication/division.')
assert.match(css, /aspect-ratio:\s*9\s*\/\s*16/, 'Co-host camera panes must preserve a 9:16 portrait ratio.')
assert.match(css, /bottom:\s*auto/, 'Co-host panes must not stretch from top to bottom of the viewport.')
assert.doesNotMatch(css, /\.fv-cohost-video-tile\s*\{[\s\S]{0,220}bottom:\s*0/, 'Co-host tile must never return to a full-height vertical strip.')

assert.match(app, /stream:\s*live\.mediaStream/, 'Host co-host controller must receive the current real Live stream.')
assert.match(hostHook, /attachLocalStream\(peer, hostStreamRef\.current\)/, 'Host must return its media on the direct co-host peer.')
assert.match(hostHook, /syncLocalStream\(peerRef\.current, stream\)/, 'Host camera changes must update the active co-host peer without falling back to stale tracks.')
assert.match(peer, /export async function syncLocalStream/, 'WebRTC layer must support replacing active host tracks.')
assert.match(viewerHook, /directHostStream/, 'Self co-host must expose a direct low-latency host return stream.')
assert.match(viewerHook, /echoCancellation:\s*true[\s\S]*noiseSuppression:\s*true[\s\S]*autoGainControl:\s*true/, 'Co-host microphone capture must request acoustic echo controls.')
assert.match(viewerScreen, /muted=\{hasDirectHostAudio\}/, 'Delayed viewer audio must mute once direct co-host host audio is available.')
assert.match(tile, /audioReturnStream/, 'Self co-host tile must play the direct host audio return.')
assert.match(tile, /COHOST_RETURN_VOLUME\s*=\s*0\.32/, 'Direct host return must stay at the reduced candidate volume until physical acceptance.')
assert.match(tile, /FEEDBACK_MUTE_MS\s*=\s*1400/, 'Feedback guard mute window must remain enabled.')
assert.match(tile, /feedbackLike[\s\S]*audio\.volume\s*=\s*0/, 'Feedback guard must be able to cut the direct return when a sustained tonal loop is detected.')

console.log('Co-host physical contract passed: Safari-safe portrait geometry, direct duplex audio return, relay muting, and feedback guard are hard-locked.')
