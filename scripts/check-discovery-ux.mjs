import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const screen = read('src/components/discover/DiscoverScreen.jsx')
const liveService = read('src/services/live/liveDiscovery.js')
const creatorService = read('src/services/discovery/creatorDiscovery.js')
const creatorHook = read('src/hooks/useCreatorDiscovery.js')
const css = read('src/styles/discover/fam1-v2.css')

assert.match(app, /creatorDiscovery=\{creatorDiscovery\}/, 'Discover must receive real creator discovery data.')
assert.match(app, /followNetwork=\{followNetwork\}/, 'Discover must reuse the real follow system.')
assert.match(screen, /placeholder="Search creators or live titles"/, 'Discover search must stay available.')
assert.match(screen, /onOpenLiveRoom/, 'Live cards must open the real viewer room.')
assert.match(screen, /followNetwork\?\.toggleFollow\?\.\(creator\.id\)/, 'Recommended Follow must use the real follow handler.')
assert.match(screen, /room\.fameTaps/, 'Live cards must use authoritative Fame totals rather than invented engagement counts.')
assert.match(screen, /No demo streams or fake viewer counts/, 'Empty state must preserve the no-fake-data rule.')
assert.doesNotMatch(screen, /1\.2K|2\.7K|23\.4K|15\.6K|JayWorld|StarGirl|Luna/, 'Discovery must not ship mock creators or mock counts from the design reference.')
assert.match(liveService, /from\('live_tap_totals'\)/, 'Discover live engagement must come from the authoritative tap totals table.')
assert.match(liveService, /listActiveLiveRooms\(\)/, 'Live Now must come from authoritative Live Presence.')
assert.match(creatorService, /from\('profiles'\)/, 'Recommended creators must come from real profiles.')
assert.match(creatorService, /from\('follows'\)/, 'Follower totals must derive from real follows.')
assert.match(creatorHook, /listRecommendedCreators/, 'Creator discovery hook must call the real discovery service.')
assert.match(css, /\.fv-discover-live-grid/, 'Approved Explore-style Live Now grid must remain styled.')
assert.match(css, /\.fv-discover-creator-list/, 'Recommended creator list must remain styled.')
assert.match(css, /grid-template-columns:\s*repeat\(2, minmax\(0, 1fr\)\)/, 'Phone Discover must keep the two-card Live Now layout.')

console.log('Discovery checks passed: real rooms, real profiles, real follows, no mock data, and Explore layout are locked.')
