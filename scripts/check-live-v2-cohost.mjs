import { readFile } from 'node:fs/promises'

const main = await readFile(new URL('../src/main.jsx', import.meta.url), 'utf8')
const base = await readFile(new URL('../src/styles/live/host-live-v2.css', import.meta.url), 'utf8')
const cohostCss = await readFile(new URL('../src/styles/live/host-live-v2-cohost.css', import.meta.url), 'utf8')
const host = await readFile(new URL('../src/components/live/HostLiveV2.jsx', import.meta.url), 'utf8')

const failures = []
const baseImport = "import './styles/live/host-live-v2.css'"
const cohostImport = "import './styles/live/host-live-v2-cohost.css'"

if (!main.includes(baseImport)) failures.push('Host Live V2 base stylesheet is not imported.')
if (!main.includes(cohostImport)) failures.push('Host Live V2 co-host stylesheet is not imported.')
if (main.indexOf(cohostImport) < main.indexOf(baseImport)) failures.push('Host Live V2 co-host stylesheet must load after the base V2 stylesheet.')

if (!host.includes("cohostStream ? 'has-cohost' : ''")) failures.push('Host Live V2 no longer exposes the co-host layout state.')
if (!host.includes('<CohostVideoTile')) failures.push('Host Live V2 no longer renders the co-host video tile.')

for (const required of [
  '.fv2-host-live.has-cohost',
  '.fv2-host-live.has-cohost .fv2-stage > .fv2-video.is-active',
  '.fv2-host-live.has-cohost .fv-cohost-video-tile',
  'width: var(--fv2-cohost-size) !important',
  'height: var(--fv2-cohost-size) !important',
  'object-fit: cover !important',
  '-webkit-backdrop-filter: none !important',
  'backdrop-filter: none !important',
]) {
  if (!cohostCss.includes(required)) failures.push(`Host Live V2 co-host contract is missing: ${required}`)
}

for (const required of [
  '.fv2-stage',
  '.fv2-video',
  'width: 100%',
  'height: 100%',
  'object-fit: cover',
]) {
  if (!base.includes(required)) failures.push(`Single-host full-canvas contract changed: ${required}`)
}

if (cohostCss.includes('.fv2-topbar') || cohostCss.includes('.fv2-composer')) {
  failures.push('Co-host layout must not reposition the approved Live V2 header or composer.')
}

if (failures.length) {
  console.error('Host Live V2 co-host regression lock failed:')
  failures.forEach((failure) => console.error(`- ${failure}`))
  process.exit(1)
}

console.log('Host Live V2 co-host regression lock passed: single host remains full-canvas; co-host uses two equal tiles without moving approved UI.')
