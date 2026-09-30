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
    throw new Error(`Expected ${expectedCount} occurrences in ${path}, found ${count}`)
  }
  write(path, source.split(before).join(after))
}

const components = 'native/flutter_v1/lib/features/live/native_live_components.dart'
replaceAllExpected(
  components,
  'final safeMs = rawMs.clamp(1500, 15000);',
  'final safeMs = rawMs.clamp(1500, 15000).toInt();',
  2,
)
replaceOnce(
  components,
  "  FvGiftDefinition get _selected =>\n      fvGiftById(_selectedId) ?? _visible.firstOrNull ?? fvGiftCatalog.first;",
  "  FvGiftDefinition get _selected {\n    final selected = fvGiftById(_selectedId);\n    if (selected != null) return selected;\n    final visible = _visible;\n    return visible.isNotEmpty ? visible.first : fvGiftCatalog.first;\n  }",
)

const catalog = 'native/flutter_v1/lib/data/fameverse_live_backend.dart'
const catalogSource = read(catalog)
if (!catalogSource.includes("id: 'fame-burst'")) {
  replaceOnce(
    catalog,
    "  FvGiftDefinition(\n    id: 'welcome-to-fameverse',",
    "  FvGiftDefinition(\n    id: 'fame-burst',\n    label: 'Fame Burst',\n    cost: 100,\n    category: 'fameverse',\n    activityEmoji: '✦',\n  ),\n  FvGiftDefinition(\n    id: 'welcome-to-fameverse',",
  )
}

const host = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
replaceOnce(
  host,
  "    required this.credentials,\n    super.key,\n  });\n\n  final FameverseLiveBackend liveBackend;\n  final FvIdentity identity;\n  final FvLiveRoom room;\n  final FvLiveCredentials credentials;",
  "    required this.credentials,\n    this.onGiftPressed,\n    this.giftButtonEnabled = true,\n    super.key,\n  });\n\n  final FameverseLiveBackend liveBackend;\n  final FvIdentity identity;\n  final FvLiveRoom room;\n  final FvLiveCredentials credentials;\n  final VoidCallback? onGiftPressed;\n  final bool giftButtonEnabled;",
)
replaceOnce(
  host,
  "    _giftTimer = Timer(\n      Duration(milliseconds: next.gift.cinematic ? 6800 : 1800),\n      _playNextGift,\n    );",
  "    // Renderer completion advances normally; this only prevents a deadlock.\n    _giftTimer = Timer(const Duration(seconds: 20), _playNextGift);",
)
replaceOnce(
  host,
  "                        const SizedBox(width: 4),\n                        FvFameActionButton(\n                          keyValue: const Key('host-f-menu-button'),",
  "                        if (widget.onGiftPressed != null) ...[\n                          const SizedBox(width: 4),\n                          IconButton.filled(\n                            key: const Key('owner-host-gift-button'),\n                            onPressed: widget.giftButtonEnabled\n                                ? widget.onGiftPressed\n                                : null,\n                            style: IconButton.styleFrom(\n                              backgroundColor: const Color(0xFF211529),\n                              foregroundColor: const Color(0xFFFFC65A),\n                              side: const BorderSide(color: Color(0xFF4B365B)),\n                            ),\n                            icon: const Icon(Icons.card_giftcard_rounded),\n                            tooltip: 'Gifts',\n                          ),\n                        ],\n                        const SizedBox(width: 4),\n                        FvFameActionButton(\n                          keyValue: const Key('host-f-menu-button'),",
)
replaceOnce(
  host,
  "                playback: _giftPlayback!,\n              ),",
  "                playback: _giftPlayback!,\n                onFinished: _playNextGift,\n              ),",
)

const viewer = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
replaceOnce(
  viewer,
  "    _giftTimer = Timer(\n      Duration(milliseconds: next.gift.cinematic ? 6800 : 1800),\n      _playNextGift,\n    );",
  "    // Renderer completion advances normally; this only prevents a deadlock.\n    _giftTimer = Timer(const Duration(seconds: 20), _playNextGift);",
)
replaceOnce(
  viewer,
  "                          if (_canRefill) ...[\n                            const SizedBox(width: 4),\n                            IconButton.filled(\n                              key: const Key('viewer-gift-button'),\n                              onPressed: _walletReady ? _showGiftTray : null,\n                              style: IconButton.styleFrom(\n                                backgroundColor: const Color(0xFF211529),\n                                foregroundColor: const Color(0xFFFFC65A),\n                                side: const BorderSide(\n                                  color: Color(0xFF4B365B),\n                                ),\n                              ),\n                              icon: const Icon(Icons.card_giftcard_rounded),\n                              tooltip: 'Gifts',\n                            ),\n                          ],",
  "                          const SizedBox(width: 4),\n                          IconButton.filled(\n                            key: const Key('viewer-gift-button'),\n                            onPressed: _walletReady ? _showGiftTray : null,\n                            style: IconButton.styleFrom(\n                              backgroundColor: const Color(0xFF211529),\n                              foregroundColor: const Color(0xFFFFC65A),\n                              side: const BorderSide(\n                                color: Color(0xFF4B365B),\n                              ),\n                            ),\n                            icon: const Icon(Icons.card_giftcard_rounded),\n                            tooltip: 'Gifts',\n                          ),",
)
replaceOnce(
  viewer,
  "                  playback: _giftPlayback!,\n                ),",
  "                  playback: _giftPlayback!,\n                  onFinished: _playNextGift,\n                ),",
)

const wrapper = 'native/flutter_v1/lib/features/live/stream_owner_host_live_screen.dart'
replaceOnce(
  wrapper,
  "      _giftTimer = Timer(\n        Duration(milliseconds: gift.cinematic ? 6800 : 1800),\n        () {\n          if (mounted) setState(() => _giftPlayback = null);\n        },\n      );",
  "      _giftTimer = Timer(const Duration(seconds: 20), () {\n        if (mounted) setState(() => _giftPlayback = null);\n      });",
)
replaceOnce(
  wrapper,
  "        base.NativeHostLiveScreen(\n          liveBackend: widget.liveBackend,\n          identity: widget.identity,\n          room: widget.room,\n          credentials: widget.credentials,\n        ),",
  "        base.NativeHostLiveScreen(\n          liveBackend: widget.liveBackend,\n          identity: widget.identity,\n          room: widget.room,\n          credentials: widget.credentials,\n          onGiftPressed: _qaGiftAllowed ? _showGiftTray : null,\n          giftButtonEnabled: !_giftBusy,\n        ),",
)
replaceOnce(
  wrapper,
  "        if (_qaGiftAllowed)\n          Positioned(\n            right: 20,\n            bottom: MediaQuery.paddingOf(context).bottom + 78,\n            child: SafeArea(\n              minimum: EdgeInsets.zero,\n              child: Semantics(\n                label: 'Owner QA gifts',\n                button: true,\n                child: Container(\n                  width: 50,\n                  height: 50,\n                  decoration: BoxDecoration(\n                    shape: BoxShape.circle,\n                    gradient: const LinearGradient(\n                      begin: Alignment.topLeft,\n                      end: Alignment.bottomRight,\n                      colors: [Color(0xFFC464FF), Color(0xFF6A28B7)],\n                    ),\n                    border: Border.all(color: const Color(0xFFE0A7FF)),\n                    boxShadow: const [\n                      BoxShadow(color: Color(0x887D2FC4), blurRadius: 16),\n                    ],\n                  ),\n                  child: IconButton(\n                    key: const Key('owner-host-gift-button'),\n                    onPressed: _giftBusy ? null : _showGiftTray,\n                    tooltip: 'QA gifts',\n                    icon: const Icon(Icons.card_giftcard_rounded),\n                  ),\n                ),\n              ),\n            ),\n          ),\n",
  '',
)
replaceOnce(
  wrapper,
  "            playback: _giftPlayback!,\n          ),",
  "            playback: _giftPlayback!,\n            onFinished: () {\n              _giftTimer?.cancel();\n              if (mounted) setState(() => _giftPlayback = null);\n            },\n          ),",
)

const baseline = 'native/flutter_v1/test/build27_baseline_contract_test.dart'
replaceOnce(
  baseline,
  "      final wrapper = File(\n        'lib/features/live/stream_owner_host_live_screen.dart',\n      ).readAsStringSync();\n      final liveExport = File(\n        'lib/features/live/stream_live_screen.dart',\n      ).readAsStringSync();\n\n      expect(wrapper, contains(\"Key('owner-host-gift-button')\"));\n      expect(wrapper, contains(\"'record_beta_gift'\"));",
  "      final wrapper = File(\n        'lib/features/live/stream_owner_host_live_screen.dart',\n      ).readAsStringSync();\n      final host = File(\n        'lib/features/live/stream_host_live_screen.dart',\n      ).readAsStringSync();\n      final liveExport = File(\n        'lib/features/live/stream_live_screen.dart',\n      ).readAsStringSync();\n\n      expect(host, contains(\"Key('owner-host-gift-button')\"));\n      expect(wrapper, contains(\"'record_beta_gift'\"));",
)

const contract = `import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live gifting and owner payout repair', () {
    test('gift tray stays reduced to five human-sized categories', () {
      final tray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      for (final value in <String>[
        "('trending', 'Trending')",
        "('support', 'Support')",
        "('fun', 'Fun')",
        "('luxury', 'Luxury')",
        "('fameverse', 'Fameverse')",
      ]) {
        expect(tray, contains(value));
      }
      expect(tray, isNot(contains("('classic', 'Classic')")));
      expect(tray, isNot(contains("('sports', 'Sports')")));
    });

    test('100 coin Fame Burst is client-visible and server-authoritative', () {
      final backend = File(
        'lib/data/fameverse_live_backend.dart',
      ).readAsStringSync();
      expect(backend, contains("id: 'fame-burst'"));
      expect(backend, contains("label: 'Fame Burst'"));
      expect(backend, contains('cost: 100'));
    });

    test('viewer gifting is not owner-refill gated', () {
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      expect(viewer, contains("Key('viewer-gift-button')"));
      expect(
        viewer,
        isNot(contains("if (_canRefill) ...[\n                            const SizedBox(width: 4),\n                            IconButton.filled(\n                              key: const Key('viewer-gift-button')")),
      );
      expect(viewer, contains('canRefill: _canRefill'));
    });

    test('host owner gift control lives in the composer and wrapper has no floater', () {
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final wrapper = File(
        'lib/features/live/stream_owner_host_live_screen.dart',
      ).readAsStringSync();
      expect(host, contains("Key('owner-host-gift-button')"));
      expect(host, contains('onGiftPressed'));
      expect(wrapper, contains('onGiftPressed: _qaGiftAllowed'));
      expect(
        wrapper,
        isNot(contains('bottom: MediaQuery.paddingOf(context).bottom + 78')),
      );
    });

    test('gift playback is completion-driven instead of fixed 6.8 second chopping', () {
      final tray = File(
        'lib/features/live/native_live_components.dart',
      ).readAsStringSync();
      final host = File(
        'lib/features/live/stream_host_live_screen.dart',
      ).readAsStringSync();
      final viewer = File(
        'lib/features/live/stream_viewer_live_screen.dart',
      ).readAsStringSync();
      expect(tray, contains('onFinished'));
      expect(host, contains('onFinished: _playNextGift'));
      expect(viewer, contains('onFinished: _playNextGift'));
      expect(host, isNot(contains('6800')));
      expect(viewer, isNot(contains('6800')));
    });

    test('owner payout review controls call the owner moderation backend', () {
      final owner = File(
        'lib/features/profile/owner_control_center_build23.dart',
      ).readAsStringSync();
      expect(owner, contains('get_creator_payout_moderation_queue'));
      expect(owner, contains('review_creator_payout'));
      expect(owner, contains('begin_creator_payout_processing'));
      expect(owner, contains("Key('owner-payout-approve')"));
      expect(owner, contains("Key('owner-payout-mark-paid')"));
    });
  });
}
`
write('native/flutter_v1/test/live_gift_and_owner_payout_contract_test.dart', contract)

console.log('Applied exact Fameverse integration Live repair patch.')
