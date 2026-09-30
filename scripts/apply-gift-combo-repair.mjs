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

function replaceAllExpected(path, before, after, expectedCount) {
  const source = read(path)
  const count = source.split(before).length - 1
  if (count !== expectedCount) {
    throw new Error(`Expected ${expectedCount} patch targets in ${path}, found ${count}`)
  }
  write(path, source.split(before).join(after))
}

const components = 'native/flutter_v1/lib/features/live/native_live_components.dart'
replaceOnce(
  components,
  `class FvGiftPlayback {\n  const FvGiftPlayback({\n    required this.gift,\n    required this.quantity,\n    required this.sender,\n  });\n\n  final FvGiftDefinition gift;\n  final int quantity;\n  final String sender;\n}\n`,
  `class FvGiftPlayback {\n  const FvGiftPlayback({\n    required this.gift,\n    required this.quantity,\n    required this.sender,\n    this.comboIndex = 1,\n    this.comboTotal = 1,\n  });\n\n  final FvGiftDefinition gift;\n  final int quantity;\n  final String sender;\n  final int comboIndex;\n  final int comboTotal;\n\n  String get visualCountLabel {\n    if (comboTotal > 1) return ' · Combo ×$comboIndex';\n    if (quantity > 1) return ' · ×$quantity';\n    return '';\n  }\n}\n\nconst int fvMaxSequentialGiftCombo = 50;\n\nList<FvGiftPlayback> fvExpandGiftVisualCombo(FvGiftPlayback playback) {\n  if (playback.quantity <= 1 ||\n      playback.quantity > fvMaxSequentialGiftCombo) {\n    return <FvGiftPlayback>[playback];\n  }\n\n  return List<FvGiftPlayback>.generate(\n    playback.quantity,\n    (index) => FvGiftPlayback(\n      gift: playback.gift,\n      quantity: 1,\n      sender: playback.sender,\n      comboIndex: index + 1,\n      comboTotal: playback.quantity,\n    ),\n    growable: false,\n  );\n}\n`,
)
replaceAllExpected(
  components,
  "'${playback.sender}${playback.quantity > 1 ? ' · ×${playback.quantity}' : ''}',",
  "'${playback.sender}${playback.visualCountLabel}',",
  2,
)
replaceOnce(
  components,
  "          if (playback.quantity > 1)\n            Positioned(\n              left: 20,\n              right: 20,\n              bottom: 92,\n              child: Text(\n                '×${playback.quantity}',",
  "          if (playback.comboTotal > 1 || playback.quantity > 1)\n            Positioned(\n              left: 20,\n              right: 20,\n              bottom: 92,\n              child: Text(\n                playback.comboTotal > 1\n                    ? 'COMBO ×${playback.comboIndex}'\n                    : '×${playback.quantity}',",
)

for (const path of [
  'native/flutter_v1/lib/features/live/stream_host_live_screen.dart',
  'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart',
]) {
  replaceOnce(
    path,
    `  void _enqueueGift(FvGiftPlayback playback) {\n    _giftQueue.add(playback);\n    if (_giftPlayback == null) _playNextGift();\n  }`,
    `  void _enqueueGift(FvGiftPlayback playback) {\n    _giftQueue.addAll(fvExpandGiftVisualCombo(playback));\n    if (_giftPlayback == null) _playNextGift();\n  }`,
  )
}

const wrapper = 'native/flutter_v1/lib/features/live/stream_owner_host_live_screen.dart'
replaceOnce(
  wrapper,
  `  int _gifterLevel = 1;\n  int _giftSerial = 0;\n  FvGiftPlayback? _giftPlayback;\n  Timer? _giftTimer;`,
  `  int _gifterLevel = 1;\n  int _giftSerial = 0;\n  final List<FvGiftPlayback> _giftQueue = <FvGiftPlayback>[];\n  FvGiftPlayback? _giftPlayback;\n  Timer? _giftTimer;`,
)
replaceOnce(
  wrapper,
  `      if (mounted) {\n        setState(() {\n          _walletBalance = nextBalance;\n          _gifterLevel = nextLevel;\n          _giftPlayback = playback;\n          _giftSerial += 1;\n        });\n      }`,
  `      if (mounted) {\n        setState(() {\n          _walletBalance = nextBalance;\n          _gifterLevel = nextLevel;\n        });\n      }\n      _enqueueQaGift(playback);`,
)
replaceOnce(
  wrapper,
  `      _giftTimer?.cancel();\n      _giftTimer = Timer(const Duration(seconds: 20), () {\n        if (mounted) setState(() => _giftPlayback = null);\n      });\n      return true;`,
  `      return true;`,
)
replaceOnce(
  wrapper,
  `  void _showGiftTray() {`,
  `  void _enqueueQaGift(FvGiftPlayback playback) {\n    _giftQueue.addAll(fvExpandGiftVisualCombo(playback));\n    if (_giftPlayback == null) _playNextQaGift();\n  }\n\n  void _playNextQaGift() {\n    _giftTimer?.cancel();\n    if (_giftQueue.isEmpty) {\n      if (mounted) setState(() => _giftPlayback = null);\n      return;\n    }\n    final next = _giftQueue.removeAt(0);\n    if (mounted) {\n      setState(() {\n        _giftPlayback = next;\n        _giftSerial += 1;\n      });\n    }\n    _giftTimer = Timer(const Duration(seconds: 20), _playNextQaGift);\n  }\n\n  void _showGiftTray() {`,
)
replaceOnce(
  wrapper,
  `  void dispose() {\n    _giftTimer?.cancel();`,
  `  void dispose() {\n    _giftTimer?.cancel();\n    _giftQueue.clear();`,
)
replaceOnce(
  wrapper,
  `            onFinished: () {\n              _giftTimer?.cancel();\n              if (mounted) setState(() => _giftPlayback = null);\n            },`,
  `            onFinished: _playNextQaGift,`,
)

const contractPath = 'native/flutter_v1/test/gift_combo_contract_test.dart'
const contract = `import 'dart:io';\n\nimport 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  group('Gift combo regression law', () {\n    test('preset combo quantities replay sequentially without re-charging', () {\n      final components = File(\n        'lib/features/live/native_live_components.dart',\n      ).readAsStringSync();\n      final viewer = File(\n        'lib/features/live/stream_viewer_live_screen.dart',\n      ).readAsStringSync();\n      final host = File(\n        'lib/features/live/stream_host_live_screen.dart',\n      ).readAsStringSync();\n      final owner = File(\n        'lib/features/live/stream_owner_host_live_screen.dart',\n      ).readAsStringSync();\n\n      expect(components, contains('fvMaxSequentialGiftCombo = 50'));\n      expect(components, contains('fvExpandGiftVisualCombo'));\n      expect(components, contains(r\"return ' · Combo ×$comboIndex'\"));\n      expect(viewer, contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'));\n      expect(host, contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'));\n      expect(owner, contains('_giftQueue.addAll(fvExpandGiftVisualCombo(playback))'));\n      expect(owner, contains(\"'record_beta_gift'\"));\n      expect(viewer, contains('quantity: quantity'));\n    });\n\n    test('huge custom quantities collapse to one visual summary instead of queue explosion', () {\n      final components = File(\n        'lib/features/live/native_live_components.dart',\n      ).readAsStringSync();\n      expect(\n        components,\n        contains('playback.quantity > fvMaxSequentialGiftCombo'),\n      );\n      expect(components, contains('return <FvGiftPlayback>[playback]'));\n    });\n  });\n}\n`
write(contractPath, contract)

console.log('Applied exact Fameverse gift combo repair.')
