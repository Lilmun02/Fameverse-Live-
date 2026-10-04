import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)

async function read(path) {
  return readFile(new URL(path, root), 'utf8')
}

async function write(path, content) {
  await writeFile(new URL(path, root), content, 'utf8')
}

function replaceExact(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[build23-patch] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[build23-patch] ${label}: expected source block was not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let changed = false

// PATCH 1 — Owner Control Center parse blocker.
{
  const path = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart'
  let source = await read(path)
  if (!source.includes("r'Enter an amount greater than $0.'")) {
    source = replaceExact(
      source,
      "_message('Enter an amount greater than $0.');",
      "_message(r'Enter an amount greater than $0.');",
      'owner control center dollar literal',
    )
    changed = true
    await write(path, source)
  }
}

// PATCH 2 — Flip-camera spam/concurrency bug.
{
  const path = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let source = await read(path)

  if (!source.includes('bool _flipCameraBusy = false;')) {
    source = replaceExact(
      source,
      '  bool _cameraEnabled = true;\n  int _fameTaps = 0;',
      '  bool _cameraEnabled = true;\n  bool _flipCameraBusy = false;\n  int _fameTaps = 0;',
      'flip camera busy state',
    )
    changed = true
  }

  if (!source.includes('_flipCameraBusy) {')) {
    source = replaceExact(
      source,
      `  Future<void> _flipCamera() async {\n    final call = _call;\n    if (call == null || _connecting || _ending || !_cameraEnabled) return;\n    try {\n      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    }\n  }`,
      `  Future<void> _flipCamera() async {\n    final call = _call;\n    if (call == null ||\n        _connecting ||\n        _ending ||\n        !_cameraEnabled ||\n        _flipCameraBusy) {\n      return;\n    }\n\n    if (mounted) {\n      setState(() => _flipCameraBusy = true);\n    } else {\n      _flipCameraBusy = true;\n    }\n\n    try {\n      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    } finally {\n      if (mounted) {\n        setState(() => _flipCameraBusy = false);\n      } else {\n        _flipCameraBusy = false;\n      }\n    }\n  }`,
      'flip camera serialized operation',
    )
    changed = true
  }

  if (!source.includes('_cameraEnabled && !_flipCameraBusy')) {
    source = replaceExact(
      source,
      `                    onPressed: _cameraEnabled\n                        ? () {\n                            Navigator.of(context).pop();\n                            unawaited(_flipCamera());\n                          }\n                        : null,`,
      `                    onPressed: _cameraEnabled && !_flipCameraBusy\n                        ? () {\n                            Navigator.of(context).pop();\n                            unawaited(_flipCamera());\n                          }\n                        : null,`,
      'flip button disabled while flip is running',
    )
    changed = true
  }

  await write(path, source)
}

// PATCH 3 — Verification must come from backend status, never a hardcoded check.
{
  const path = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart'
  let source = await read(path)
  if (!source.includes('class _Build23VerificationBadge extends StatefulWidget')) {
    source = replaceExact(
      source,
      `              const SizedBox(width: 6),\n              Icon(\n                isOwner\n                    ? Icons.workspace_premium_rounded\n                    : Icons.verified_rounded,\n                color: isOwner\n                    ? const Color(0xFFFFD27D)\n                    : const Color(0xFFA95AFF),\n                size: 21,\n              ),`,
      `              _Build23VerificationBadge(\n                userId: profile.id,\n                isOwner: isOwner,\n              ),`,
      'profile verification badge source',
    )
    source += `\n\nclass _Build23VerificationBadge extends StatefulWidget {\n  const _Build23VerificationBadge({required this.userId, required this.isOwner});\n  final String userId;\n  final bool isOwner;\n  @override\n  State<_Build23VerificationBadge> createState() => _Build23VerificationBadgeState();\n}\n\nclass _Build23VerificationBadgeState extends State<_Build23VerificationBadge> {\n  bool _verified = false;\n  @override\n  void initState() {\n    super.initState();\n    if (!widget.isOwner) _loadVerification();\n  }\n  @override\n  void didUpdateWidget(covariant _Build23VerificationBadge oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (oldWidget.userId != widget.userId || oldWidget.isOwner != widget.isOwner) {\n      if (widget.isOwner) {\n        _verified = false;\n      } else {\n        _loadVerification();\n      }\n    }\n  }\n  Future<void> _loadVerification() async {\n    try {\n      final row = await Supabase.instance.client.from('creator_verification_requests').select('status').eq('user_id', widget.userId).maybeSingle();\n      final verified = (row?['status'] as String?)?.trim().toLowerCase() == 'verified';\n      if (mounted) setState(() => _verified = verified);\n    } catch (_) {\n      if (mounted) setState(() => _verified = false);\n    }\n  }\n  @override\n  Widget build(BuildContext context) {\n    if (widget.isOwner) {\n      return const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD27D), size: 21));\n    }\n    if (!_verified) return const SizedBox.shrink();\n    return const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: Color(0xFFA95AFF), size: 21));\n  }\n}\n`
    changed = true
    await write(path, source)
  }
}

// PATCH 4 — Live comment/gift transitions must dismiss the software keyboard.
{
  const hostPath = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let host = await read(hostPath)
  if (!host.includes('_comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();')) {
    host = replaceExact(
      host,
      `      _comment.clear();\n    });\n    try {`,
      `      _comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();\n    try {`,
      'host comment keyboard dismissal',
    )
    changed = true
    await write(hostPath, host)
  }

  const viewerPath = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
  let viewer = await read(viewerPath)
  if (!viewer.includes('_comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();')) {
    viewer = replaceExact(
      viewer,
      `      _comment.clear();\n    });\n    try {`,
      `      _comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();\n    try {`,
      'viewer comment keyboard dismissal',
    )
    changed = true
  }
  if (!viewer.includes('if (_giftSending) return false;\n    FocusManager.instance.primaryFocus?.unfocus();')) {
    viewer = replaceExact(
      viewer,
      `  Future<bool> _sendGift(FvGiftDefinition gift, int quantity) async {\n    if (_giftSending) return false;`,
      `  Future<bool> _sendGift(FvGiftDefinition gift, int quantity) async {\n    if (_giftSending) return false;\n    FocusManager.instance.primaryFocus?.unfocus();`,
      'gift send keyboard dismissal',
    )
    changed = true
  }
  if (!viewer.includes('void _showGiftTray() {\n    FocusManager.instance.primaryFocus?.unfocus();')) {
    viewer = replaceExact(
      viewer,
      `  void _showGiftTray() {\n    showModalBottomSheet<void>(`,
      `  void _showGiftTray() {\n    FocusManager.instance.primaryFocus?.unfocus();\n    showModalBottomSheet<void>(`,
      'gift tray keyboard dismissal',
    )
    changed = true
  }
  await write(viewerPath, viewer)
}

// PATCH 5 — Gift chat activity is lightweight, never a giant purple card.
{
  const path = 'native/flutter_v1/lib/features/live/stream_live_shared.dart'
  let source = await read(path)
  if (source.includes('Color(0xCC1A0E24)') || source.includes('Color(0x553C0A71)')) {
    source = replaceExact(
      source,
      `            padding: isGift\n                ? const EdgeInsets.fromLTRB(9, 8, 11, 9)\n                : const EdgeInsets.symmetric(horizontal: 2, vertical: 2),\n            decoration: isGift\n                ? BoxDecoration(\n                    color: const Color(0xCC1A0E24),\n                    borderRadius: BorderRadius.circular(14),\n                    border: Border.all(\n                      color: const Color(0xFFB34EFF),\n                      width: 1.1,\n                    ),\n                    boxShadow: const [\n                      BoxShadow(color: Color(0x553C0A71), blurRadius: 10),\n                    ],\n                  )\n                : null,`,
      `            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),`,
      'gift activity oversized card removal',
    )
    changed = true
    await write(path, source)
  }
}

// PATCH 6 — Host Live must not display a fake unconditional verification check.
{
  const path = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let source = await read(path)
  if (source.includes('Icons.verified_rounded')) {
    source = replaceExact(
      source,
      `                                  const SizedBox(width: 5),\n                                  const Icon(\n                                    Icons.verified_rounded,\n                                    size: 16,\n                                    color: Color(0xFFAA62FF),\n                                  ),\n                                  const SizedBox(width: 6),\n                                  const FvLiveBadge(),`,
      `                                  const SizedBox(width: 6),\n                                  const FvLiveBadge(),`,
      'host live fake verification badge removal',
    )
    changed = true
    await write(path, source)
  }
}

// PATCH 7 — Co-host camera flip gets the same anti-spam serialization as host Live.
{
  const path = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
  let source = await read(path)

  if (!source.includes('bool _cohostFlipBusy = false;')) {
    source = replaceExact(
      source,
      '  bool _cohostCameraEnabled = true;\n  bool _cohostMicEnabled = true;',
      '  bool _cohostCameraEnabled = true;\n  bool _cohostFlipBusy = false;\n  bool _cohostMicEnabled = true;',
      'cohost flip busy state',
    )
    changed = true
  }

  if (!source.includes('_cohostFlipBusy) {')) {
    source = replaceExact(
      source,
      `  Future<void> _flipCohostCamera() async {\n    if (!_selfIsCohost || !_cohostCameraEnabled || _call == null) return;\n    try {\n      fvRequireSuccess(await _call!.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    }\n  }`,
      `  Future<void> _flipCohostCamera() async {\n    final call = _call;\n    if (!_selfIsCohost ||\n        !_cohostCameraEnabled ||\n        call == null ||\n        _cohostFlipBusy) {\n      return;\n    }\n\n    if (mounted) {\n      setState(() => _cohostFlipBusy = true);\n    } else {\n      _cohostFlipBusy = true;\n    }\n\n    try {\n      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    } finally {\n      if (mounted) {\n        setState(() => _cohostFlipBusy = false);\n      } else {\n        _cohostFlipBusy = false;\n      }\n    }\n  }`,
      'cohost flip serialized operation',
    )
    changed = true
  }

  if (!source.includes('_cohostCameraEnabled && !_cohostFlipBusy')) {
    source = replaceExact(
      source,
      `                      onPressed: _cohostCameraEnabled\n                          ? () {\n                              Navigator.of(context).pop();\n                              unawaited(_flipCohostCamera());\n                            }\n                          : null,`,
      `                      onPressed: _cohostCameraEnabled && !_cohostFlipBusy\n                          ? () {\n                              Navigator.of(context).pop();\n                              unawaited(_flipCohostCamera());\n                            }\n                          : null,`,
      'cohost flip button disabled while flip is running',
    )
    changed = true
  }

  await write(path, source)
}

// PATCH 8 — The Fame Coins profile card itself opens the public coin store.
{
  const path = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart'
  let source = await read(path)

  if (!source.includes("Key('profile-fame-coins-card')")) {
    source = replaceExact(
      source,
      `  @override\n  Widget build(BuildContext context) {\n    return Container(\n      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),`,
      `  @override\n  Widget build(BuildContext context) {\n    return GestureDetector(\n      key: const Key('profile-fame-coins-card'),\n      behavior: HitTestBehavior.opaque,\n      onTap: _loading ? null : _openStore,\n      child: Container(\n        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),`,
      'profile Fame Coins whole-card tap',
    )
    source = replaceExact(
      source,
      `          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _Build23SettingsScreen extends StatelessWidget {`,
      `          ),\n        ],\n      ),\n      ),\n    );\n  }\n}\n\nclass _Build23SettingsScreen extends StatelessWidget {`,
      'profile Fame Coins whole-card wrapper close',
    )
    changed = true
    await write(path, source)
  }
}

// PATCH 9 — Host rankings belong under creator info, never beside End; compact creator text keeps the name readable.
{
  const path = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let source = await read(path)

  if (!source.includes("key: const Key('host-live-rankings-left')")) {
    source = replaceExact(
      source,
      `                                      style: const TextStyle(\n                                        fontSize: 15,\n                                        fontWeight: FontWeight.w900,\n                                        letterSpacing: .2,\n                                      ),`,
      `                                      style: const TextStyle(\n                                        fontSize: 12,\n                                        fontWeight: FontWeight.w900,\n                                        letterSpacing: .1,\n                                      ),`,
      'compact host live creator name',
    )
    source = replaceExact(
      source,
      `                                style: const TextStyle(\n                                  color: Color(0xFFD6CADC),\n                                  fontSize: 11,\n                                  fontWeight: FontWeight.w600,\n                                ),\n                              ),\n                            ],`,
      `                                style: const TextStyle(\n                                  color: Color(0xFFD6CADC),\n                                  fontSize: 9.5,\n                                  fontWeight: FontWeight.w600,\n                                ),\n                              ),\n                              const SizedBox(height: 3),\n                              Align(\n                                alignment: Alignment.centerLeft,\n                                child: TextButton.icon(\n                                  key: const Key('host-live-rankings-left'),\n                                  onPressed: () => unawaited(\n                                    showNativeLiveRankings(context),\n                                  ),\n                                  style: TextButton.styleFrom(\n                                    foregroundColor: const Color(0xFFFFC75A),\n                                    minimumSize: Size.zero,\n                                    padding: const EdgeInsets.symmetric(\n                                      horizontal: 1,\n                                      vertical: 1,\n                                    ),\n                                    tapTargetSize:\n                                        MaterialTapTargetSize.shrinkWrap,\n                                    visualDensity: VisualDensity.compact,\n                                  ),\n                                  icon: const Icon(\n                                    Icons.emoji_events_rounded,\n                                    size: 12,\n                                  ),\n                                  label: const Text(\n                                    'Rankings',\n                                    style: TextStyle(\n                                      fontSize: 9,\n                                      fontWeight: FontWeight.w800,\n                                    ),\n                                  ),\n                                ),\n                              ),\n                            ],`,
      'move host rankings under creator info',
    )
    source = replaceExact(
      source,
      `                        const SizedBox(width: 4),\n                        IconButton(\n                          key: const Key('host-live-rankings-button'),\n                          onPressed: () =>\n                              unawaited(showNativeLiveRankings(context)),\n                          constraints: const BoxConstraints.tightFor(\n                            width: 32,\n                            height: 32,\n                          ),\n                          padding: EdgeInsets.zero,\n                          visualDensity: VisualDensity.compact,\n                          icon: const Icon(\n                            Icons.emoji_events_rounded,\n                            size: 17,\n                            color: Color(0xFFFFC75A),\n                          ),\n                          tooltip: 'Rankings',\n                        ),\n                        const SizedBox(width: 4),`,
      `                        const SizedBox(width: 6),`,
      'remove rankings from beside End',
    )
    changed = true
    await write(path, source)
  }
}

console.log(
  changed
    ? '[build23-patch] Applied exact bug patches; formatter will persist them.'
    : '[build23-patch] Source already contains all Build 23 bug patches.',
)
