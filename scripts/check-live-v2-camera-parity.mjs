import { readFile } from 'node:fs/promises'

const main = await readFile(new URL('../src/main.jsx', import.meta.url), 'utf8')
const host = await readFile(new URL('../src/components/live/HostLiveV2.jsx', import.meta.url), 'utf8')
const media = await readFile(new URL('../src/hooks/useLiveMedia.js', import.meta.url), 'utf8')
const lock = await readFile(new URL('../src/styles/live/host-live-v2-video-lock.css', import.meta.url), 'utf8')

const failures = []
const hostCssImport = "./styles/live/host-live-v2.css"
const lockImport = "./styles/live/host-live-v2-video-lock.css"
const hostCssIndex = main.indexOf(hostCssImport)
const lockIndex = main.indexOf(lockImport)

if (hostCssIndex < 0 || lockIndex < 0 || lockIndex < hostCssIndex) {
  failures.push('Host Live V2 video lock must load after the base Host Live V2 stylesheet.')
}

const slotCount = (host.match(/className={`fv2-video/g) || []).length
if (slotCount !== 2) failures.push(`Expected exactly two Host Live V2 camera slots, found ${slotCount}.`)

const requiredLockSnippets = [
  'display: block !important;',
  'object-fit: cover !important;',
  '-webkit-transform: translateZ(0) !important;',
  'transform: translateZ(0) !important;',
  '-webkit-transform: translateZ(0) scaleX(-1) !important;',
  'transform: translateZ(0) scaleX(-1) !important;',
  'will-change: transform, opacity;',
]

for (const snippet of requiredLockSnippets) {
  if (!lock.includes(snippet)) failures.push(`Camera compositor parity lock is missing: ${snippet}`)
}

if (/\.fv2-host-live \.fv2-stage > \.fv2-video\s*\{[\s\S]*?display:\s*none/i.test(lock)) {
  failures.push('Camera slots must never use display:none in the final V2 video lock.')
}

if (!media.includes('const activeVideo = getVideoElement(activeVideoSlot)')) {
  failures.push('Camera flip must reuse the currently rendered full-screen video element.')
}
if (!media.includes('configureVideo(activeVideo, nextStream)')) {
  failures.push('Replacement camera stream must be attached to the same active video element.')
}
if (!media.includes('await waitForVideoFrame(activeVideo)')) {
  failures.push('Camera handoff must wait for a real frame on the active video before completing.')
}
if (media.includes('const nextSlot = activeVideoSlot === 0 ? 1 : 0')) {
  failures.push('iPhone camera flip must not switch to a second rendered WebKit video compositor.')
}
if (media.includes('setActiveVideoSlot(nextSlot)')) {
  failures.push('Camera flip must never change rendered video slots after Live starts.')
}

if (failures.length) {
  console.error('Host Live V2 camera parity guard failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  process.exit(1)
}

console.log('Host Live V2 camera parity guard passed: camera flips stay on one full-screen rendered video compositor.')
