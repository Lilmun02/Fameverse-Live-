import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)

async function read(path) {
  return readFile(new URL(path, root), 'utf8')
}

async function write(path, content) {
  await writeFile(new URL(path, root), content, 'utf8')
}

function replaceOnce(content, before, after, label) {
  if (content.includes(after)) return { content, changed: false }
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[build23-patch] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[build23-patch] ${label}: expected source block was not unique`)
  }
  return {
    content: content.slice(0, first) + after + content.slice(first + before.length),
    changed: true,
  }
}

let changed = false

// PATCH 1 — Owner Control Center parse blocker.
{
  const path = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart'
  let source = await read(path)
  const result = replaceOnce(
    source,
    "_message('Enter an amount greater than $0.');",
    "_message(r'Enter an amount greater than $0.');",
    'owner control center dollar literal',
  )
  source = result.content
  changed ||= result.changed
  if (result.changed) await write(path, source)
}

// PATCH 2 — Flip-camera spam/concurrency bug.
{
  const path = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let source = await read(path)

  let result = replaceOnce(
    source,
    '  bool _cameraEnabled = true;\n  int _fameTaps = 0;',
    '  bool _cameraEnabled = true;\n  bool _flipCameraBusy = false;\n  int _fameTaps = 0;',
    'flip camera busy state',
  )
  source = result.content
  changed ||= result.changed

  result = replaceOnce(
    source,
    `  Future<void> _flipCamera() async {\n    final call = _call;\n    if (call == null || _connecting || _ending || !_cameraEnabled) return;\n    try {\n      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    }\n  }`,
    `  Future<void> _flipCamera() async {\n    final call = _call;\n    if (call == null ||\n        _connecting ||\n        _ending ||\n        !_cameraEnabled ||\n        _flipCameraBusy) {\n      return;\n    }\n\n    if (mounted) {\n      setState(() => _flipCameraBusy = true);\n    } else {\n      _flipCameraBusy = true;\n    }\n\n    try {\n      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');\n    } catch (_) {\n      if (mounted) _showMessage('Camera flip failed.');\n    } finally {\n      if (mounted) {\n        setState(() => _flipCameraBusy = false);\n      } else {\n        _flipCameraBusy = false;\n      }\n    }\n  }`,
    'flip camera serialized operation',
  )
  source = result.content
  changed ||= result.changed

  result = replaceOnce(
    source,
    `                    onPressed: _cameraEnabled\n                        ? () {\n                            Navigator.of(context).pop();\n                            unawaited(_flipCamera());\n                          }\n                        : null,`,
    `                    onPressed: _cameraEnabled && !_flipCameraBusy\n                        ? () {\n                            Navigator.of(context).pop();\n                            unawaited(_flipCamera());\n                          }\n                        : null,`,
    'flip button disabled while flip is running',
  )
  source = result.content
  changed ||= result.changed

  await write(path, source)
}

// PATCH 3 — Verification must come from backend status, never a hardcoded check.
{
  const path = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart'
  let source = await read(path)

  const oldBadge = `              const SizedBox(width: 6),\n              Icon(\n                isOwner\n                    ? Icons.workspace_premium_rounded\n                    : Icons.verified_rounded,\n                color: isOwner\n                    ? const Color(0xFFFFD27D)\n                    : const Color(0xFFA95AFF),\n                size: 21,\n              ),`
  const newBadge = `              _Build23VerificationBadge(\n                userId: profile.id,\n                isOwner: isOwner,\n              ),`
  let result = replaceOnce(
    source,
    oldBadge,
    newBadge,
    'profile verification badge source',
  )
  source = result.content
  changed ||= result.changed

  if (!source.includes('class _Build23VerificationBadge extends StatefulWidget')) {
    source += `\n\nclass _Build23VerificationBadge extends StatefulWidget {\n  const _Build23VerificationBadge({\n    required this.userId,\n    required this.isOwner,\n  });\n\n  final String userId;\n  final bool isOwner;\n\n  @override\n  State<_Build23VerificationBadge> createState() =>\n      _Build23VerificationBadgeState();\n}\n\nclass _Build23VerificationBadgeState\n    extends State<_Build23VerificationBadge> {\n  bool _verified = false;\n\n  @override\n  void initState() {\n    super.initState();\n    if (!widget.isOwner) _loadVerification();\n  }\n\n  @override\n  void didUpdateWidget(covariant _Build23VerificationBadge oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (oldWidget.userId != widget.userId || oldWidget.isOwner != widget.isOwner) {\n      if (widget.isOwner) {\n        _verified = false;\n      } else {\n        _loadVerification();\n      }\n    }\n  }\n\n  Future<void> _loadVerification() async {\n    try {\n      final row = await Supabase.instance.client\n          .from('creator_verification_requests')\n          .select('status')\n          .eq('user_id', widget.userId)\n          .maybeSingle();\n      final verified =\n          (row?['status'] as String?)?.trim().toLowerCase() == 'verified';\n      if (mounted) setState(() => _verified = verified);\n    } catch (_) {\n      if (mounted) setState(() => _verified = false);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    if (widget.isOwner) {\n      return const Padding(\n        padding: EdgeInsets.only(left: 6),\n        child: Icon(\n          Icons.workspace_premium_rounded,\n          color: Color(0xFFFFD27D),\n          size: 21,\n        ),\n      );\n    }\n    if (!_verified) return const SizedBox.shrink();\n    return const Padding(\n      padding: EdgeInsets.only(left: 6),\n      child: Icon(\n        Icons.verified_rounded,\n        color: Color(0xFFA95AFF),\n        size: 21,\n      ),\n    );\n  }\n}\n`
    changed = true
  }

  await write(path, source)
}

// PATCH 4 — Live comment/gift transitions must dismiss the software keyboard.
{
  const hostPath = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let host = await read(hostPath)
  let result = replaceOnce(
    host,
    `      _comment.clear();\n    });\n    try {`,
    `      _comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();\n    try {`,
    'host comment keyboard dismissal',
  )
  host = result.content
  changed ||= result.changed
  await write(hostPath, host)

  const viewerPath = 'native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart'
  let viewer = await read(viewerPath)
  result = replaceOnce(
    viewer,
    `      _comment.clear();\n    });\n    try {`,
    `      _comment.clear();\n    });\n    FocusManager.instance.primaryFocus?.unfocus();\n    try {`,
    'viewer comment keyboard dismissal',
  )
  viewer = result.content
  changed ||= result.changed

  result = replaceOnce(
    viewer,
    `  Future<bool> _sendGift(FvGiftDefinition gift, int quantity) async {\n    if (_giftSending) return false;`,
    `  Future<bool> _sendGift(FvGiftDefinition gift, int quantity) async {\n    if (_giftSending) return false;\n    FocusManager.instance.primaryFocus?.unfocus();`,
    'gift send keyboard dismissal',
  )
  viewer = result.content
  changed ||= result.changed

  result = replaceOnce(
    viewer,
    `  void _showGiftTray() {\n    showModalBottomSheet<void>(`,
    `  void _showGiftTray() {\n    FocusManager.instance.primaryFocus?.unfocus();\n    showModalBottomSheet<void>(`,
    'gift tray keyboard dismissal',
  )
  viewer = result.content
  changed ||= result.changed
  await write(viewerPath, viewer)
}

// PATCH 5 — Gift chat activity is lightweight, never a giant purple card.
{
  const path = 'native/flutter_v1/lib/features/live/stream_live_shared.dart'
  let source = await read(path)
  const result = replaceOnce(
    source,
    `            padding: isGift\n                ? const EdgeInsets.fromLTRB(9, 8, 11, 9)\n                : const EdgeInsets.symmetric(horizontal: 2, vertical: 2),\n            decoration: isGift\n                ? BoxDecoration(\n                    color: const Color(0xCC1A0E24),\n                    borderRadius: BorderRadius.circular(14),\n                    border: Border.all(\n                      color: const Color(0xFFB34EFF),\n                      width: 1.1,\n                    ),\n                    boxShadow: const [\n                      BoxShadow(color: Color(0x553C0A71), blurRadius: 10),\n                    ],\n                  )\n                : null,`,
    `            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),`,
    'gift activity oversized card removal',
  )
  source = result.content
  changed ||= result.changed
  await write(path, source)
}

// PATCH 6 — Host Live must not display a fake unconditional verification check.
{
  const path = 'native/flutter_v1/lib/features/live/stream_host_live_screen.dart'
  let source = await read(path)
  const result = replaceOnce(
    source,
    `                                  const SizedBox(width: 5),\n                                  const Icon(\n                                    Icons.verified_rounded,\n                                    size: 16,\n                                    color: Color(0xFFAA62FF),\n                                  ),\n                                  const SizedBox(width: 6),\n                                  const FvLiveBadge(),`,
    `                                  const SizedBox(width: 6),\n                                  const FvLiveBadge(),`,
    'host live fake verification badge removal',
  )
  source = result.content
  changed ||= result.changed
  await write(path, source)
}

console.log(
  changed
    ? '[build23-patch] Applied exact bug patches; formatter will persist them.'
    : '[build23-patch] Source already contains all Build 23 bug patches.',
)
