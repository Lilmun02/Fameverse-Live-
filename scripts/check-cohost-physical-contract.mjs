import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const main = read('src/main.jsx')
const hostHook = read('src/hooks/useCohostHost.js')
const viewerHook = read('src/hooks/useCohostViewer.js')
const viewerScreen = read('src/components/live/ViewerLiveScreen.jsx')
const tile = read('src/components/live/CohostVideoTile.jsx')
const peer = read('src/services/live/webrtcPeer.js')
const squareCss = read('src/styles/live/cohost-square-lock.css')

assert.match(main, /import '\.\/styles\/live\/live-contract\.css'[\s\S]*import '\.\/styles\/live\/cohost-square-lock\.css'/, 'Square co-host contract must load after every other Live layout stylesheet.')
assert.match(squareCss, /--fv-cohost-square-size:\s*min\(50vw,\s*44dvh,\s*420px\)/, 'Each co-host camera box must use the shared square size token.')
assert.match(squareCss, /width:\s*var\(--fv-cohost-square-size\)\s*!important;[\s\S]*height:\s*var\(--fv-cohost-square-size\)\s*!important;/, 'Co-host box width and height must be identical.')
assert.match(squareCss, /aspect-ratio:\s*1\s*\/\s*1\s*!important/, 'Co-host cameras must be square, never portrait picture frames.')
assert.doesNotMatch(squareCss, /aspect-ratio:\s*9\s*\/\s*16/, 'Final co-host layout must never restore 9:16 portrait panes.')
assert.match(squareCss, /left:\s*var\(--fv-cohost-square-size\)\s*!important/, 'Co-host square must sit immediately beside the host square.')
assert.match(squareCss, /bottom:\s*auto\s*!important/, 'Square camera boxes must not stretch to the bottom of the viewport.')

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

console.log('Co-host physical contract passed: square side-by-side geometry, direct duplex audio return, relay muting, and feedback guard are hard-locked.')
