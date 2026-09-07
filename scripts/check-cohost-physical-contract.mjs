import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const main = read('src/main.jsx')
const hostHook = read('src/hooks/useCohostHost.js')
const viewerHook = read('src/hooks/useCohostViewer.js')
const liveScreen = read('src/components/live/LiveScreen.jsx')
const liveActions = read('src/components/live/LiveActions.jsx')
const viewerScreen = read('src/components/live/ViewerLiveScreen.jsx')
const tile = read('src/components/live/CohostVideoTile.jsx')
const peer = read('src/services/live/webrtcPeer.js')
const css = read('src/styles/live/cohost.css')

assert.match(main, /import '\.\/styles\/live\/live-contract\.css'\s*\nimport '\.\/styles\/live\/cohost\.css'/, 'Canonical co-host CSS must load last after the general Live contract.')
assert.doesNotMatch(main, /cohost-square-lock\.css/, 'Do not layer a second co-host override stylesheet over the canonical contract.')
assert.match(css, /--fv-cohost-square-size:\s*min\(50vw,\s*44dvh,\s*420px\)/, 'Each co-host camera box must use the shared square size token.')
assert.match(css, /width:\s*var\(--fv-cohost-square-size\)\s*!important;[\s\S]*height:\s*var\(--fv-cohost-square-size\)\s*!important;/, 'Co-host camera width and height must be identical.')
assert.match(css, /aspect-ratio:\s*1\s*\/\s*1\s*!important/, 'Co-host cameras must be square.')
assert.doesNotMatch(css, /aspect-ratio:\s*9\s*\/\s*16/, 'Portrait picture-frame co-host panes are forbidden.')
assert.doesNotMatch(css, /--fv-cohost-pane-height/, 'Legacy portrait pane height token must not exist.')
assert.match(css, /left:\s*var\(--fv-cohost-square-size\)\s*!important/, 'Co-host square must sit directly beside the host square.')
assert.match(css, /bottom:\s*auto\s*!important/, 'Square camera boxes must not stretch to the bottom of the viewport.')
assert.match(css, /\.fv-cohost-invite-prompt/, 'Viewer Accept/Decline invitation prompt styling must remain present.')

assert.match(app, /stream:\s*live\.mediaStream/, 'Host co-host controller must receive the current real Live stream.')
assert.match(hostHook, /attachLocalStream\(peer, hostStreamRef\.current\)/, 'Host must return its media on the direct co-host peer.')
assert.match(hostHook, /syncLocalStream\(peerRef\.current, stream\)/, 'Host camera changes must update the active co-host peer without falling back to stale tracks.')
assert.match(peer, /export async function syncLocalStream/, 'WebRTC layer must support replacing active host tracks.')
assert.match(viewerHook, /directHostStream/, 'Self co-host must expose a direct low-latency host return stream.')
assert.match(viewerHook, /echoCancellation:\s*true[\s\S]*noiseSuppression:\s*true[\s\S]*autoGainControl:\s*true/, 'Co-host microphone capture must request acoustic echo controls.')
assert.match(viewerScreen, /const hostPlaybackStream = isSelfCohost && cohost\.directHostStream[\s\S]*\? cohost\.directHostStream[\s\S]*: relay\.remoteStream/, 'Self co-host must switch the main host player to the direct host stream instead of layering a second audio return.')
assert.match(viewerScreen, /video\.srcObject = hostPlaybackStream \|\| null/, 'The main host video element must own the active host audio/video playback path.')
assert.doesNotMatch(viewerScreen, /muted=\{hasDirectHostAudio\}/, 'Do not mute one host player while starting a second host audio element.')
assert.doesNotMatch(viewerScreen, /audioReturnStream=/, 'Viewer screen must not create a second host audio return path.')
assert.match(tile, /muted=\{local\}/, 'A co-host must never hear their own local microphone through their self-preview tile.')
assert.doesNotMatch(tile, /<audio|AudioContext|FEEDBACK_MUTE_MS|audioReturnStream/, 'Co-host tile must not run a second audio element or feedback analyser that can chop or scratch the return audio.')

assert.doesNotMatch(liveScreen, /CohostSheet/, 'Host must not render a second nested co-host sheet; the single F menu owns co-host controls.')
assert.match(liveScreen, /<LiveActions[\s\S]*cohost=\{cohost\}/, 'The single host F menu must receive the real co-host controller.')
assert.match(liveActions, /cohost\?\.inviteViewer\?\.\(viewer\)/, 'Host F menu must wire viewer invitations to the real co-host controller.')
assert.match(liveActions, /cohost\?\.acceptRequest\?\.\(request\)/, 'Host F menu must wire request acceptance.')
assert.match(liveActions, /cohost\?\.declineRequest\?\.\(request\)/, 'Host F menu must wire request decline.')
assert.match(liveActions, /cohost\?\.cancelInvite/, 'Host F menu must wire invitation cancellation.')
assert.match(liveActions, /cohost\?\.endCohost/, 'Host F menu must wire active co-host removal.')
assert.match(css, /\.fam-live-control-menu\.has-cohost-controls/, 'Co-host controls must stay inside the adaptive host F menu styling contract.')

console.log('Co-host static contract passed: square layout, one audible host return path, self-preview muted, viewer invite prompt preserved, and one wired host F menu.')
