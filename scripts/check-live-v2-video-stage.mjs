import { readFile } from 'node:fs/promises'

const main = await readFile(new URL('../src/main.jsx', import.meta.url), 'utf8')
const lock = await readFile(new URL('../src/styles/live/host-live-v2-video-lock.css', import.meta.url), 'utf8')
const host = await readFile(new URL('../src/components/live/HostLiveV2.jsx', import.meta.url), 'utf8')

const failures = []
const importLine = "import './styles/live/host-live-v2-video-lock.css'"
const baseImportLine = "import './styles/live/host-live-v2.css'"

if (!main.includes(importLine)) failures.push('Live V2 video-stage lock CSS is not imported.')
if (main.indexOf(importLine) < main.indexOf(baseImportLine)) failures.push('Live V2 video-stage lock must load after the base Host Live V2 stylesheet.')

for (const required of [
  '.fv2-host-live .fv2-stage',
  '.fv2-host-live .fv2-stage > .fv2-video',
  'display: block !important',
  'width: 100% !important',
  'height: 100% !important',
  'object-fit: cover !important',
  'opacity: 0',
  '.fv2-host-live .fv2-stage > .fv2-video.is-active',
  'opacity: 1',
]) {
  if (!lock.includes(required)) failures.push(`Live V2 video-stage lock is missing: ${required}`)
}

const videoNodes = (host.match(/<video\b/g) || []).length
if (videoNodes !== 2) failures.push(`Host Live V2 must keep exactly two warm camera video slots; found ${videoNodes}.`)
if (!host.includes("activeVideoSlot === 0 ? 'is-active' : ''") || !host.includes("activeVideoSlot === 1 ? 'is-active' : ''")) {
  failures.push('Host Live V2 active camera-slot switching contract changed.')
}

if (failures.length) {
  console.error('Host Live V2 video-stage regression lock failed:')
  failures.forEach((failure) => console.error(`- ${failure}`))
  process.exit(1)
}

console.log('Host Live V2 video-stage regression lock passed: both camera slots stay full-canvas and switch by opacity only.')
