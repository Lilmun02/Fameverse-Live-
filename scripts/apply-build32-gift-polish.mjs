import { readFile, writeFile, unlink } from 'node:fs/promises'

const root = new URL('../', import.meta.url)

async function read(path) {
  return readFile(new URL(path, root), 'utf8')
}

async function write(path, content) {
  await writeFile(new URL(path, root), content, 'utf8')
}

function replaceOnce(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[build32-gift-polish] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[build32-gift-polish] ${label}: expected source block was not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let changed = false

// GIFT PATCH 1 — Pocket Comet was explicitly retired by the owner.
{
  const path = 'native/flutter_v1/lib/data/fameverse_live_backend.dart'
  let source = await read(path)
  const pocketComet = `  FvGiftDefinition(\n    id: 'pocket-comet',\n    label: 'Pocket Comet',\n    cost: 1000,\n    category: 'fameverse',\n    activityEmoji: '☄️',\n    cinematic: true,\n  ),\n`
  if (source.includes("id: 'pocket-comet'")) {
    source = replaceOnce(source, pocketComet, '', 'remove Pocket Comet catalog entry')
    await write(path, source)
    changed = true
  }
  if (source.includes("id: 'pocket-comet'")) {
    throw new Error('[build32-gift-polish] Pocket Comet remains in native catalog')
  }
}

// GIFT PATCH 2 — Preserve approved cinematic presentation. A previous Build 32
// patch globally muted cinematic MP4 audio without explicit owner approval.
// Restore the original player volume behavior; future asset audio changes must
// come from explicit owner approval, not this stabilization patch.
{
  const path = 'native/flutter_v1/lib/features/live/native_live_components.dart'
  let source = await read(path)

  if (source.includes("import 'native_pocket_comet_gift.dart';\n")) {
    source = replaceOnce(
      source,
      "import 'native_pocket_comet_gift.dart';\n",
      '',
      'remove Pocket Comet renderer import',
    )
    changed = true
  }

  if (source.includes("    if (gift.id == 'pocket-comet') return const Duration(milliseconds: 4300);\n")) {
    source = replaceOnce(
      source,
      "    if (gift.id == 'pocket-comet') return const Duration(milliseconds: 4300);\n",
      '',
      'remove Pocket Comet duration override',
    )
    changed = true
  }

  if (source.includes('await _controller!.setVolume(0);')) {
    source = replaceOnce(
      source,
      'await _controller!.setVolume(0);',
      'await _controller!.setVolume(1);',
      'restore replayed cinematic gift audio',
    )
    changed = true
  }

  if (source.includes('await next.setVolume(0);')) {
    source = replaceOnce(
      source,
      'await next.setVolume(0);',
      'await next.setVolume(1);',
      'restore initialized cinematic gift audio',
    )
    changed = true
  }

  const pocketCometRenderer = `    if (playback.gift.id == 'pocket-comet') {\n      return Stack(\n        fit: StackFit.expand,\n        children: [\n          NativePocketCometGift(sender: playback.sender),\n          if (playback.comboTotal > 1 || playback.quantity > 1)\n            Positioned(\n              left: 20,\n              right: 20,\n              bottom: 92,\n              child: Text(\n                playback.comboTotal > 1\n                    ? 'COMBO ×\${playback.comboIndex}'\n                    : '×\${playback.quantity}',\n                textAlign: TextAlign.center,\n                style: const TextStyle(\n                  color: Color(0xFFFFE7A2),\n                  fontSize: 22,\n                  fontWeight: FontWeight.w900,\n                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],\n                ),\n              ),\n            ),\n        ],\n      );\n    }\n\n`
  if (source.includes("playback.gift.id == 'pocket-comet'")) {
    source = replaceOnce(
      source,
      pocketCometRenderer,
      '',
      'remove Pocket Comet playback renderer',
    )
    changed = true
  }

  if (source.includes('pocket-comet') || source.includes('NativePocketCometGift')) {
    throw new Error('[build32-gift-polish] Pocket Comet remains in live components')
  }

  await write(path, source)
}

// GIFT PATCH 3 — Remove Pocket Comet-only poster art and dead renderer file.
{
  const path = 'native/flutter_v1/lib/features/live/native_gift_visual.dart'
  let source = await read(path)
  if (source.includes("gift.id == 'pocket-comet'")) {
    source = `import 'package:flutter/material.dart';\n\nimport '../../data/fameverse_live_backend.dart';\n\n/// Stable gift-store poster art.\n///\n/// Cinematic gifts use deterministic poster art in the tray; the remote video\n/// plays only after a successful send.\nclass NativeGiftTrayVisual extends StatelessWidget {\n  const NativeGiftTrayVisual({required this.gift, this.size = 54, super.key});\n\n  final FvGiftDefinition gift;\n  final double size;\n\n  @override\n  Widget build(BuildContext context) {\n    if (gift.cinematic) {\n      return SizedBox.square(\n        dimension: size,\n        child: DecoratedBox(\n          decoration: BoxDecoration(\n            borderRadius: BorderRadius.circular(12),\n            gradient: const LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Color(0xFF4A2564), Color(0xFF24142F), Color(0xFF17101F)],\n            ),\n            border: Border.all(color: const Color(0x335F37A1)),\n          ),\n          child: Center(\n            child: Text(gift.symbol, style: TextStyle(fontSize: size * .46)),\n          ),\n        ),\n      );\n    }\n\n    return SizedBox.square(\n      dimension: size,\n      child: Center(\n        child: Text(gift.symbol, style: TextStyle(fontSize: size * .52)),\n      ),\n    );\n  }\n}\n`
    await write(path, source)
    changed = true
  }
  if (source.includes('pocket-comet') || source.includes('PocketComet')) {
    throw new Error('[build32-gift-polish] Pocket Comet poster code remains')
  }

  const deadRenderer = new URL(
    'native/flutter_v1/lib/features/live/native_pocket_comet_gift.dart',
    root,
  )
  try {
    await unlink(deadRenderer)
    changed = true
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error
  }
}

console.log(
  changed
    ? '[build32-gift-polish] Applied owner-authorized Pocket Comet retirement and restored cinematic asset presentation.'
    : '[build32-gift-polish] Build 32 gift state already matches owner-approved boundaries.',
)
