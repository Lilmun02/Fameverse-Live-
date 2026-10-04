import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)
const path = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart'

const read = () => readFile(new URL(path, root), 'utf8')
const write = (content) => writeFile(new URL(path, root), content, 'utf8')

function replaceOnce(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) throw new Error(`[verification-moderation-patch] ${label}: source block missing`)
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[verification-moderation-patch] ${label}: source block not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let source = await read()
let changed = false

if (!source.includes('List<Map<String, dynamic>> _verificationQueue = const [];')) {
  source = replaceOnce(
    source,
    `  List<Map<String, dynamic>> _payouts = const [];\n`,
    `  List<Map<String, dynamic>> _payouts = const [];\n  List<Map<String, dynamic>> _verificationQueue = const [];\n`,
    'verification queue state',
  )
  changed = true
}

if (!source.includes("'get_creator_verification_moderation_queue'")) {
  source = replaceOnce(
    source,
    `        _client.rpc(\n          'get_creator_payout_moderation_queue',\n          params: const {'p_limit': 50},\n        ),\n`,
    `        _client.rpc(\n          'get_creator_payout_moderation_queue',\n          params: const {'p_limit': 50},\n        ),\n        _client.rpc(\n          'get_creator_verification_moderation_queue',\n          params: const {'p_limit': 50},\n        ),\n`,
    'verification moderation query',
  )
  source = replaceOnce(
    source,
    `        _payouts = _rows(results[2]);\n        _loading = false;\n`,
    `        _payouts = _rows(results[2]);\n        _verificationQueue = _rows(results[3]);\n        _loading = false;\n`,
    'verification queue assignment',
  )
  changed = true
}

if (!source.includes('Future<void> _reviewVerification(')) {
  source = replaceOnce(
    source,
    `  Future<void> _reviewPayout(Map<String, dynamic> payout, String status) async {\n`,
    `  Future<void> _reviewVerification(\n    Map<String, dynamic> request,\n    String status,\n  ) async {\n    if (_busy) return;\n    final userId = request['user_id']?.toString();\n    if (userId == null || userId.isEmpty) return;\n    setState(() => _busy = true);\n    try {\n      await _client.rpc(\n        'review_creator_verification',\n        params: {\n          'p_user_id': userId,\n          'p_status': status,\n          'p_public_note': status == 'verified'\n              ? 'Creator verification approved by Fameverse review.'\n              : status == 'needs_info'\n              ? 'More information is required before verification can be approved.'\n              : 'Verification request was not approved.',\n        },\n      );\n      _message('Verification updated to \${status.replaceAll('_', ' ')}.');\n      await _refresh();\n    } catch (_) {\n      _message('Could not update creator verification.');\n    } finally {\n      if (mounted) setState(() => _busy = false);\n    }\n  }\n\n  Future<void> _reviewPayout(Map<String, dynamic> payout, String status) async {\n`,
    'verification moderation action',
  )
  changed = true
}

if (!source.includes("const _Section('VERIFICATION REVIEW')")) {
  source = replaceOnce(
    source,
    `              else ...[\n                const _Section('PAYOUT REVIEW'),\n`,
    `              else ...[\n                const _Section('VERIFICATION REVIEW'),\n                const SizedBox(height: 10),\n                if (_verificationQueue.isEmpty)\n                  const _Notice(\n                    icon: Icons.verified_user_outlined,\n                    title: 'No verification requests waiting',\n                    body:\n                        'Pending creator verification requests will appear here for owner review.',\n                  )\n                else\n                  ..._verificationQueue.map(\n                    (request) => Padding(\n                      padding: const EdgeInsets.only(bottom: 10),\n                      child: _VerificationReviewCard(\n                        request: request,\n                        busy: _busy,\n                        onApprove: () =>\n                            _reviewVerification(request, 'verified'),\n                        onNeedsInfo: () =>\n                            _reviewVerification(request, 'needs_info'),\n                        onReject: () =>\n                            _reviewVerification(request, 'rejected'),\n                      ),\n                    ),\n                  ),\n                const SizedBox(height: 20),\n                const _Section('PAYOUT REVIEW'),\n`,
    'verification moderation UI section',
  )
  changed = true
}

if (!source.includes('class _VerificationReviewCard extends StatelessWidget')) {
  source = replaceOnce(
    source,
    `class _PayoutCard extends StatelessWidget {\n`,
    `class _VerificationReviewCard extends StatelessWidget {\n  const _VerificationReviewCard({\n    required this.request,\n    required this.busy,\n    required this.onApprove,\n    required this.onNeedsInfo,\n    required this.onReject,\n  });\n\n  final Map<String, dynamic> request;\n  final bool busy;\n  final VoidCallback onApprove;\n  final VoidCallback onNeedsInfo;\n  final VoidCallback onReject;\n\n  @override\n  Widget build(BuildContext context) {\n    final displayName =\n        request['display_name']?.toString() ?? 'Fameverse Creator';\n    final username = request['username']?.toString();\n    final status = request['status']?.toString() ?? 'pending';\n    final userId = request['user_id']?.toString() ?? 'unknown';\n    return Container(\n      key: Key('owner-verification-$userId'),\n      padding: const EdgeInsets.all(16),\n      decoration: BoxDecoration(\n        color: const Color(0xFF17111B),\n        borderRadius: BorderRadius.circular(20),\n        border: Border.all(color: const Color(0xFF4A3553)),\n      ),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Text(\n            displayName,\n            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),\n          ),\n          if (username != null && username.isNotEmpty)\n            Text(\n              '@$username',\n              style: const TextStyle(color: Color(0xFFA89CAE)),\n            ),\n          const SizedBox(height: 8),\n          Chip(label: Text(status.replaceAll('_', ' '))),\n          const SizedBox(height: 10),\n          Wrap(\n            spacing: 8,\n            runSpacing: 8,\n            children: [\n              FilledButton(\n                key: const Key('owner-verification-approve'),\n                onPressed: busy ? null : onApprove,\n                child: const Text('Verify'),\n              ),\n              FilledButton.tonal(\n                key: const Key('owner-verification-needs-info'),\n                onPressed: busy ? null : onNeedsInfo,\n                child: const Text('Needs info'),\n              ),\n              TextButton(\n                key: const Key('owner-verification-reject'),\n                onPressed: busy ? null : onReject,\n                child: const Text('Reject'),\n              ),\n            ],\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _PayoutCard extends StatelessWidget {\n`,
    'verification moderation card',
  )
  changed = true
}

for (const marker of [
  "'get_creator_verification_moderation_queue'",
  "'review_creator_verification'",
  "Key('owner-verification-approve')",
  "Key('owner-verification-needs-info')",
  "Key('owner-verification-reject')",
]) {
  if (!source.includes(marker)) {
    throw new Error(`[verification-moderation-patch] missing required marker: ${marker}`)
  }
}

if (changed) await write(source)
console.log(
  changed
    ? '[verification-moderation-patch] Added owner verification review controls.'
    : '[verification-moderation-patch] Verification review controls already present.',
)
