import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)
const discoverPath = 'native/flutter_v1/lib/features/shell/fameverse_discover_screen.dart'
const rankingsPath = 'native/flutter_v1/lib/features/live/native_live_rankings.dart'

const read = (path) => readFile(new URL(path, root), 'utf8')
const write = (path, content) => writeFile(new URL(path, root), content, 'utf8')

function replaceOnce(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) throw new Error(`[build32-rankings] ${label}: source block missing`)
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[build32-rankings] ${label}: source block not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let discover = await read(discoverPath)
let changed = false

if (!discover.includes("import '../live/native_live_rankings.dart';")) {
  discover = replaceOnce(
    discover,
    "import '../../data/fameverse_backend.dart';\n",
    "import '../../data/fameverse_backend.dart';\nimport '../live/native_live_rankings.dart';\n",
    'Discover Fameboard import',
  )
  changed = true
}

if (!discover.includes("Key('discover-fameboard-card')")) {
  discover = replaceOnce(
    discover,
    `            const SizedBox(height: 28),\n            if (widget.loading &&`,
    `            const SizedBox(height: 16),\n            const _DiscoverFameboardCard(),\n            const SizedBox(height: 28),\n            if (widget.loading &&`,
    'Discover Fameboard placement',
  )

  discover = replaceOnce(
    discover,
    `class _DiscoverTopBar extends StatelessWidget {\n`,
    `class _DiscoverFameboardCard extends StatelessWidget {\n  const _DiscoverFameboardCard();\n\n  @override\n  Widget build(BuildContext context) {\n    return Material(\n      color: Colors.transparent,\n      child: InkWell(\n        key: const Key('discover-fameboard-card'),\n        onTap: () => showNativeLiveRankings(context),\n        borderRadius: BorderRadius.circular(22),\n        child: Ink(\n          padding: const EdgeInsets.all(16),\n          decoration: BoxDecoration(\n            borderRadius: BorderRadius.circular(22),\n            border: Border.all(color: const Color(0xFF5B3970)),\n            gradient: const LinearGradient(\n              begin: Alignment.topLeft,\n              end: Alignment.bottomRight,\n              colors: [Color(0xFF321846), Color(0xFF191020), Color(0xFF100B14)],\n            ),\n          ),\n          child: const Row(\n            children: [\n              _DiscoverFameboardMark(),\n              SizedBox(width: 13),\n              Expanded(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    Text(\n                      'FAMEBOARD',\n                      style: TextStyle(\n                        color: Color(0xFFC88BFF),\n                        fontSize: 10,\n                        fontWeight: FontWeight.w900,\n                        letterSpacing: 1.5,\n                      ),\n                    ),\n                    SizedBox(height: 4),\n                    Text(\n                      'Who is moving Fameverse?',\n                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),\n                    ),\n                    SizedBox(height: 3),\n                    Text(\n                      'Explore Supporters, Pulse and Creators across 24H and 7D windows.',\n                      style: TextStyle(color: Color(0xFFA99DAE), fontSize: 10, height: 1.3),\n                    ),\n                  ],\n                ),\n              ),\n              SizedBox(width: 8),\n              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFC697EB)),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n\nclass _DiscoverFameboardMark extends StatelessWidget {\n  const _DiscoverFameboardMark();\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      width: 46,\n      height: 46,\n      decoration: BoxDecoration(\n        borderRadius: BorderRadius.circular(15),\n        gradient: const LinearGradient(\n          colors: [Color(0xFFA853FF), Color(0xFF5A2BCD)],\n        ),\n      ),\n      child: const Icon(Icons.leaderboard_rounded),\n    );\n  }\n}\n\nclass _DiscoverTopBar extends StatelessWidget {\n`,
    'Discover Fameboard card',
  )
  changed = true
}

if (changed) await write(discoverPath, discover)

const rankings = await read(rankingsPath)
for (const marker of [
  "'get_fameverse_rankings_v2'",
  "'p_window': _window",
  "('24h', '24H')",
  "('7d', '7D')",
  "('supporters', 'Supporters'",
  "('pulse', 'Pulse'",
  "('creators', 'Creators'",
  "Key('fameboard-first-spotlight')",
]) {
  if (!rankings.includes(marker)) {
    throw new Error(`[build32-rankings] required Fameboard marker missing: ${marker}`)
  }
}
for (const rejected of ['Daily Ranking', 'Weekly Ranking', 'Ranking history']) {
  if (rankings.includes(rejected)) {
    throw new Error(`[build32-rankings] rejected reference terminology leaked into Fameboard: ${rejected}`)
  }
}

console.log(
  changed
    ? '[build32-rankings] Added persisted Discover Fameboard entry.'
    : '[build32-rankings] Fameboard Discover wiring already clean and idempotent.',
)
