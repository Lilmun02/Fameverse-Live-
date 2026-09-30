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
  if (first < 0) throw new Error(`Expected patch target missing in ${path}`)
  if (source.indexOf(before, first + before.length) >= 0) {
    throw new Error(`Patch target is ambiguous in ${path}`)
  }
  write(path, source.slice(0, first) + after + source.slice(first + before.length))
}

const viewer = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
replaceOnce(
  viewer,
  `              if (_giftPlayback != null)\n                NativeGiftOverlay(\n                  key: ValueKey('viewer-gift-$_giftSerial'),\n                  playback: _giftPlayback!,\n                  onFinished: _playNextGift,\n                ),\n              ..._tapBursts.map(\n                (serial) => Positioned(\n                  right: 16 + (serial % 3) * 16,\n                  bottom: 86,\n                  child: IgnorePointer(\n                    child: _TapBurstParticle(serial: serial),\n                  ),\n                ),\n              ),`,
  `              ..._tapBursts.map(\n                (serial) => Positioned(\n                  right: 16 + (serial % 3) * 16,\n                  bottom: 86,\n                  child: IgnorePointer(\n                    child: _TapBurstParticle(serial: serial),\n                  ),\n                ),\n              ),\n              if (_giftPlayback != null)\n                NativeGiftOverlay(\n                  key: ValueKey('viewer-gift-$_giftSerial'),\n                  playback: _giftPlayback!,\n                  onFinished: _playNextGift,\n                ),`,
)

const contract = `import 'dart:io';\n\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  test('viewer gift overlay stays above transient tap effects', () {\n    final source = File(\n      'lib/features/live/stream_viewer_live_screen.dart',\n    ).readAsStringSync();\n\n    final tapBursts = source.indexOf('..._tapBursts.map(');\n    final giftOverlay = source.indexOf(\"ValueKey('viewer-gift-\\$_giftSerial')\");\n\n    expect(tapBursts, greaterThanOrEqualTo(0));\n    expect(giftOverlay, greaterThanOrEqualTo(0));\n    expect(\n      giftOverlay,\n      greaterThan(tapBursts),\n      reason: 'Gift playback must paint after tap particles so it cannot be visually covered.',\n    );\n  });\n}\n`
write('native/flutter_v1/test/gift_overlay_layer_contract_test.dart', contract)

console.log('Applied Fameverse viewer gift overlay layer repair.')
