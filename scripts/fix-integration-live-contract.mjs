import fs from 'node:fs'

function read(path) {
  return fs.readFileSync(path, 'utf8')
}

function write(path, value) {
  fs.writeFileSync(path, value)
}

function replaceOnce(path, before, after) {
  const source = read(path)
  const first = source.indexOf(before)
  if (first < 0) throw new Error(`Expected legacy contract target missing in ${path}`)
  if (source.indexOf(before, first + before.length) >= 0) {
    throw new Error(`Legacy contract target is ambiguous in ${path}`)
  }
  write(path, source.slice(0, first) + after + source.slice(first + before.length))
}

// Normalize the generated regression assertion so Dart sees a simple one-line
// negative gate. The product law is: normal viewers can gift; only QA refill is
// owner/admin restricted.
{
  const path = 'native/flutter_v1/test/live_gift_and_owner_payout_contract_test.dart'
  const source = read(path)
  const startMarker = `      expect(\n        viewer,\n        isNot(contains("if (_canRefill) ...[`
  const nextMarker = `      expect(viewer, contains('canRefill: _canRefill'));`
  const start = source.indexOf(startMarker)
  const next = source.indexOf(nextMarker, start)
  if (start < 0 || next < 0) {
    throw new Error('Generated viewer gift-gate assertion did not match the locked repair contract.')
  }
  write(
    path,
    `${source.slice(0, start)}      expect(viewer, isNot(contains("if (_canRefill) ...[")));\n${source.slice(next)}`,
  )
}

// Owner QA authority stays in the wrapper/RPC, but the visible entry point now
// belongs in the canonical host composer beside chat rather than a floating
// Positioned overlay.
{
  const path = 'native/flutter_v1/test/owner_host_gift_tray_contract_test.dart'
  replaceOnce(
    path,
    `    final wrapper = File(\n      'lib/features/live/stream_owner_host_live_screen.dart',\n    ).readAsStringSync();\n    final barrel = File(`,
    `    final wrapper = File(\n      'lib/features/live/stream_owner_host_live_screen.dart',\n    ).readAsStringSync();\n    final host = File(\n      'lib/features/live/stream_host_live_screen.dart',\n    ).readAsStringSync();\n    final barrel = File(`,
  )
  replaceOnce(
    path,
    `      wrapper,\n      contains("Key('owner-host-gift-button')"),\n      reason: 'The privileged host gift-tray entry point must not disappear.',`,
    `      host,\n      contains("Key('owner-host-gift-button')"),\n      reason: 'The privileged host gift entry point must stay beside the canonical composer.',`,
  )
  replaceOnce(
    path,
    `      wrapper,\n      contains('if (_qaGiftAllowed)'),\n      reason: 'Regular hosts must not receive the privileged QA gift control.',`,
    `      wrapper,\n      contains('onGiftPressed: _qaGiftAllowed ? _showGiftTray : null'),\n      reason: 'Regular hosts must not receive the privileged QA gift control.',`,
  )
}

// The old release lock accidentally encoded two bugs: viewer gifting was tied
// to the QA refill role, and inexpensive gifts were forced into a tiny pill.
// Lock the approved public gift entry point and larger deliberate renderer.
{
  const path = 'native/flutter_v1/test/live_v2_release_contract_test.dart'
  replaceOnce(
    path,
    `      expect(viewer, contains('if (_canRefill) ...['));`,
    `      expect(viewer, isNot(contains("if (_canRefill) ...[")));\n      expect(viewer, contains('canRefill: _canRefill'));`,
  )
  replaceOnce(
    path,
    `      expect(components, contains('playback.gift.cost < 100'));\n      expect(components, contains("Key('lightweight-gift-"));`,
    `      expect(components, contains("Key('native-gift-presentation-"));\n      expect(components, contains("Key('cinematic-gift-presentation-"));\n      expect(components, contains('onFinished'));`,
  )
}

// Preserve the actual visual safety law without preserving the discarded tiny
// gift pill implementation. Poster art remains deterministic and videos still
// fall back to native art instead of paused/black remote frames.
{
  const path = 'native/flutter_v1/test/sep27_gift_catalog_contract_test.dart'
  replaceOnce(
    path,
    `    expect(components, contains('deterministic native art/text'));\n    expect(components, contains('paused remote frame'));\n    expect(components, contains('cannot flash black'));\n    expect(components, contains('lightweight-gift-'));`,
    `    expect(components, contains("Key('native-gift-presentation-"));\n    expect(components, contains("Key('cinematic-gift-presentation-"));\n    expect(components, contains('VideoPlayer(controller)'));\n    expect(components, contains('BoxFit.cover'));`,
  )
}

console.log('Aligned generated and legacy Live regression contracts with the approved gifting law.')
