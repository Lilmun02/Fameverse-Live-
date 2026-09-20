import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const hostV2 = readFileSync(new URL('../src/components/live/HostLiveV2.jsx', import.meta.url), 'utf8')
const activity = readFileSync(new URL('../src/hooks/useLiveActivity.js', import.meta.url), 'utf8')
const css = readFileSync(new URL('../src/styles/live/host-live-v2.css', import.meta.url), 'utf8')

assert.match(activity, /userId:\s*payload\.userId \|\| null/, 'Remote comments must preserve the sender userId.')
assert.match(activity, /userId:\s*payload\.senderId \|\| null/, 'Remote gift activity must preserve the sender userId.')
assert.match(hostV2, /const canOpenProfile = Boolean\(item\.userId\)/, 'Host Live V2 must gate profile taps on a real userId.')
assert.match(hostV2, /className="fv2-chat-profile"[\s\S]*onClick=\{\(\) => canOpenProfile && profileSheet\.open\(item\.userId\)\}/, 'Host Live V2 chat identity must open the in-Live profile.')
assert.match(hostV2, /<LiveProfileSheet sheet=\{profileSheet\}/, 'Host Live V2 must keep the in-Live profile sheet mounted.')
assert.match(css, /\.fv2-chat-profile\s*\{[\s\S]*border:\s*0;[\s\S]*background:\s*transparent;/, 'Making chat identities tappable must not introduce a new button/card design.')

console.log('Host Live V2 profile contract passed: real userId preserved, profile tap wired, and approved chat styling preserved.')
