import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

function read(path) {
  return readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')
}

const app = read('src/App.jsx')
const activity = read('src/hooks/useLiveActivity.js')
const gifts = read('src/hooks/useGiftSystem.js')
const follows = read('src/services/follows.js')
const followHook = read('src/hooks/useFollowNetwork.js')
const profiles = read('src/services/profiles.js')
const sheetHook = read('src/hooks/useLiveProfileSheet.js')
const sheet = read('src/components/live/LiveProfileSheet.jsx')
const chat = read('src/components/live/LiveChat.jsx')
const header = read('src/components/live/LiveHeader.jsx')
const viewer = read('src/components/live/ViewerLiveScreen.jsx')
const liveScreen = read('src/components/live/LiveScreen.jsx')
const main = read('src/main.jsx')
const discover = read('src/components/discover/DiscoverScreen.jsx')

assert.match(app, /const actorId = account\.session\?\.user\?\.id/, 'Signed-in account id must be the Live identity source.')
assert.match(app, /displayName,\n\s*actorId,\n\s*setToast/, 'Gift activity must receive the signed-in actor id.')
assert.match(app, /roomId: activeActivityRoomId,[\s\S]*displayName,[\s\S]*actorId,/, 'Live activity must receive the signed-in actor id.')
assert.match(app, /currentUserId=\{actorId\}/, 'Host and viewer Live screens must receive the current user id.')

assert.match(activity, /userId: payload\.userId \|\| null/, 'Remote comments must preserve sender user ids.')
assert.match(activity, /userId: payload\.senderId \|\| null/, 'Remote gifts must preserve sender user ids.')
assert.match(activity, /userId: actorId \|\| null/, 'Local comments must carry the signed-in user id.')
assert.match(activity, /senderId: actorId \|\| null/, 'Gift broadcasts must carry the signed-in sender id.')
assert.match(gifts, /userId: actorId \|\| null/, 'Local gift chat rows must carry the signed-in user id.')

assert.match(chat, /onOpenIdentity = null/, 'LiveChat must expose identity opening.')
assert.match(chat, /onClick=\{\(\) => identityEnabled && onOpenIdentity\(item\.userId\)\}/, 'Comment avatars must open the real sender profile.')
assert.match(chat, /className="fam-chat-identity-button"/, 'Comment names must be tappable when a real user id exists.')

assert.match(header, /className="fam-live-creator-identity"/, 'Host top identity must keep the canonical no-box class.')
assert.match(header, /onOpenIdentity\(currentUserId\)/, 'Host top identity must open the host real profile.')
assert.match(liveScreen, /onOpenIdentity=\{profileSheet\.open\}/, 'Host comments must open the profile sheet.')
assert.match(liveScreen, /<LiveProfileSheet/, 'Host Live must mount the profile sheet over the Live.')
assert.match(viewer, /onClick=\{openHostProfile\}/, 'Viewer host avatar/name must open the creator profile.')
assert.match(viewer, /onOpenIdentity=\{profileSheet\.open\}/, 'Viewer comments must open the same profile sheet.')
assert.match(viewer, /<LiveProfileSheet/, 'Viewer Live must mount the profile sheet without navigating away.')
assert.doesNotMatch(viewer, /setTab\(|navigate\(/, 'Live profile interaction must not navigate away from the room.')

assert.match(sheetHook, /loadLiveIdentity/, 'Profile sheet must load real profile rows.')
assert.match(profiles, /from\('profiles'\)/, 'Profile data must come from the real profiles table.')
assert.match(profiles, /from\('follows'\)/, 'Follower/following counts must come from real follows.')
assert.match(sheet, /followNetwork\?\.toggleFollow/, 'Profile sheet Follow must reuse the real follow network.')
assert.match(sheet, /isSelf/, 'Profile sheet must block self-follow.')
assert.match(follows, /from\('follows'\)\.insert/, 'Follow writes must remain on the existing follows service.')
assert.match(followHook, /userId === targetId/, 'Existing self-follow protection must remain in force.')

assert.doesNotMatch(sheet, /Top Fan|Lv\.\s*\d|rank:/, 'Do not invent rank or Top Fan data.')
assert.doesNotMatch(profiles, /gifter|rank|badge/i, 'Profile loader must not invent backend gifter/rank fields.')
assert.doesNotMatch(discover, /LiveProfileSheet|useLiveProfileSheet/, 'Live identity work must not leak into Discovery.')
assert.doesNotMatch(liveScreen, /fv-live-stage-brand/, 'Identity work must not redesign the host Live stage.')
assert.doesNotMatch(viewer, /fv-live-stage-brand|fv-live-fall/, 'Identity work must not add unapproved viewer stage branding or falling rails.')
assert.match(viewer, /className="is-fame"><b aria-hidden="true">F<\/b>/, 'Identity work must not replace the approved Fame stat F icon.')
assert.ok(main.indexOf("./styles/live/profile-sheet.css") < main.indexOf("./styles/live/live-contract.css"), 'Final Live contract must still load after the profile sheet CSS.')

console.log('Live identity checks passed: real tappable profiles, real follows, host/viewer wiring, no fake ranks, and no scope-creep redesign.')
