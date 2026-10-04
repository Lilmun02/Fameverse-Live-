import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)
const read = (path) => readFile(new URL(path, root), 'utf8')
const write = (path, content) => writeFile(new URL(path, root), content, 'utf8')

function replaceExact(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[verification-progress] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[verification-progress] ${label}: expected source block was not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let changed = false

// Backend model/RPC wiring.
{
  const path = 'native/flutter_v1/lib/data/fameverse_creator_backend.dart'
  let source = await read(path)

  if (!source.includes('class FvCreatorVerificationProgress')) {
    const marker = `class FvCreatorPayoutRequest {`
    const addition = `class FvCreatorVerificationProgress {\n  const FvCreatorVerificationProgress({\n    required this.verificationStatus,\n    required this.followerCount,\n    required this.followerRequirement,\n    required this.eligibleReceivedCoins,\n    required this.receivedCoinsRequirement,\n    required this.eligible,\n  });\n\n  final String verificationStatus;\n  final int followerCount;\n  final int followerRequirement;\n  final int eligibleReceivedCoins;\n  final int receivedCoinsRequirement;\n  final bool eligible;\n\n  bool get isVerified => verificationStatus == 'verified';\n  bool get isPending => verificationStatus == 'pending';\n\n  factory FvCreatorVerificationProgress.fromMap(Map<String, dynamic> row) {\n    return FvCreatorVerificationProgress(\n      verificationStatus:\n          row['verification_status']?.toString().trim().toLowerCase() ??\n          'unverified',\n      followerCount: _intValue(row['follower_count']),\n      followerRequirement: _intValue(row['follower_requirement']),\n      eligibleReceivedCoins: _intValue(row['eligible_received_coins']),\n      receivedCoinsRequirement: _intValue(row['received_coins_requirement']),\n      eligible: row['eligible'] == true,\n    );\n  }\n\n  static const empty = FvCreatorVerificationProgress(\n    verificationStatus: 'unverified',\n    followerCount: 0,\n    followerRequirement: 100,\n    eligibleReceivedCoins: 0,\n    receivedCoinsRequirement: 500000,\n    eligible: false,\n  );\n}\n\n`
    source = replaceExact(source, marker, addition + marker, 'verification progress model')
    changed = true
  }

  if (!source.includes('Future<FvCreatorVerificationProgress> loadVerificationProgress()')) {
    const marker = `  Future<String> requestVerification() async {\n    final response = await _client.rpc('request_creator_verification');\n    return response?.toString() ?? 'pending';\n  }`
    const replacement = `  Future<FvCreatorVerificationProgress> loadVerificationProgress() async {\n    final response = await _client.rpc('get_creator_verification_progress');\n    final rows = _rows(response);\n    if (rows.isEmpty) return FvCreatorVerificationProgress.empty;\n    return FvCreatorVerificationProgress.fromMap(rows.first);\n  }\n\n${marker}`
    source = replaceExact(source, marker, replacement, 'verification progress RPC')
    changed = true
  }

  if (changed) await write(path, source)
}

// Creator Studio progress UI and eligibility lock.
{
  const path = 'native/flutter_v1/lib/features/profile/creator_studio_build23.dart'
  let source = await read(path)

  if (!source.includes('FvCreatorVerificationProgress _verificationProgress')) {
    source = replaceExact(
      source,
      `  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;\n  FvCreatorPayoutMethod? _payoutMethod;`,
      `  FvCreatorPayoutSummary _summary = FvCreatorPayoutSummary.empty;\n  FvCreatorVerificationProgress _verificationProgress =\n      FvCreatorVerificationProgress.empty;\n  FvCreatorPayoutMethod? _payoutMethod;`,
      'verification progress state',
    )
    changed = true
  }

  if (!source.includes('widget.backend.loadVerificationProgress(),')) {
    source = replaceExact(
      source,
      `        Supabase.instance.client.rpc(\n          'get_creator_promotional_earnings_summary',\n        ),\n      ]);`,
      `        Supabase.instance.client.rpc(\n          'get_creator_promotional_earnings_summary',\n        ),\n        widget.backend.loadVerificationProgress(),\n      ]);`,
      'verification progress refresh request',
    )
    source = replaceExact(
      source,
      `        _payoutMethod = results[2] as FvCreatorPayoutMethod?;\n        if (promoRows.isNotEmpty) {`,
      `        _payoutMethod = results[2] as FvCreatorPayoutMethod?;\n        _verificationProgress =\n            results[4] as FvCreatorVerificationProgress;\n        if (promoRows.isNotEmpty) {`,
      'verification progress refresh state',
    )
    changed = true
  }

  if (!source.includes('!_verificationProgress.eligible')) {
    source = replaceExact(
      source,
      `  Future<void> _requestVerification() async {\n    if (_busy || _summary.isVerified) return;`,
      `  Future<void> _requestVerification() async {\n    if (_busy || _summary.isVerified || !_verificationProgress.eligible) {\n      if (!_summary.isVerified && !_verificationProgress.eligible) {\n        _message('Complete both verification requirements first.');\n      }\n      return;\n    }`,
      'verification request eligibility guard',
    )
    source = replaceExact(
      source,
      `    } catch (_) {\n      _message('Could not submit verification right now.');`,
      `    } catch (error) {\n      final value = error.toString().toLowerCase();\n      _message(\n        value.contains('eligibility') || value.contains('500000')\n            ? 'Complete both verification requirements first.'\n            : 'Could not submit verification right now.',\n      );`,
      'verification request eligibility error',
    )
    changed = true
  }

  if (!source.includes('progress: _verificationProgress,')) {
    source = replaceExact(
      source,
      `                _VerificationCard(\n                  summary: _summary,\n                  busy: _busy,`,
      `                _VerificationCard(\n                  summary: _summary,\n                  progress: _verificationProgress,\n                  busy: _busy,`,
      'verification progress card wiring',
    )
    changed = true
  }

  if (!source.includes("Key('creator-verification-followers-progress')")) {
    const oldCard = `class _VerificationCard extends StatelessWidget {\n  const _VerificationCard({\n    required this.summary,\n    required this.busy,\n    required this.onRequest,\n  });\n\n  final FvCreatorPayoutSummary summary;\n  final bool busy;\n  final VoidCallback onRequest;\n\n  @override\n  Widget build(BuildContext context) {\n    final status = summary.verificationStatus;\n    final verified = summary.isVerified;\n    return _ActionCard(\n      icon: verified ? Icons.verified_rounded : Icons.verified_outlined,\n      title: 'Creator verification',\n      subtitle: verified\n          ? 'Verified for creator payout eligibility.'\n          : 'Status: \${status.replaceAll('_', ' ')}',\n      trailing: verified\n          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF72D49B))\n          : FilledButton(\n              onPressed: busy || status == 'pending' ? null : onRequest,\n              child: Text(status == 'pending' ? 'Pending' : 'Request'),\n            ),\n    );\n  }\n}\n`
    const newCard = `class _VerificationCard extends StatelessWidget {\n  const _VerificationCard({\n    required this.summary,\n    required this.progress,\n    required this.busy,\n    required this.onRequest,\n  });\n\n  final FvCreatorPayoutSummary summary;\n  final FvCreatorVerificationProgress progress;\n  final bool busy;\n  final VoidCallback onRequest;\n\n  @override\n  Widget build(BuildContext context) {\n    final status = progress.verificationStatus.isEmpty\n        ? summary.verificationStatus\n        : progress.verificationStatus;\n    final verified = status == 'verified';\n    final pending = status == 'pending';\n    final canRequest = progress.eligible && !busy && !pending && !verified;\n\n    return Container(\n      key: const Key('creator-verification-center'),\n      padding: const EdgeInsets.all(17),\n      decoration: BoxDecoration(\n        borderRadius: BorderRadius.circular(20),\n        border: Border.all(color: const Color(0xFF513862)),\n        color: const Color(0xFF17111B),\n      ),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Row(\n            children: [\n              Icon(\n                verified ? Icons.verified_rounded : Icons.verified_outlined,\n                color: verified\n                    ? const Color(0xFF72D49B)\n                    : const Color(0xFFC78BFA),\n              ),\n              const SizedBox(width: 10),\n              const Expanded(\n                child: Text(\n                  'Creator verification',\n                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),\n                ),\n              ),\n              if (verified)\n                const Icon(Icons.check_circle_rounded, color: Color(0xFF72D49B)),\n            ],\n          ),\n          const SizedBox(height: 8),\n          Text(\n            verified\n                ? 'Your creator account is verified.'\n                : pending\n                ? 'Application submitted and waiting for review.'\n                : 'Complete both requirements below to unlock the verification request.',\n            style: const TextStyle(\n              color: Color(0xFFB8ACBC),\n              fontSize: 12,\n              height: 1.4,\n            ),\n          ),\n          const SizedBox(height: 16),\n          _VerificationProgressLine(\n            key: const Key('creator-verification-followers-progress'),\n            label: 'Followers',\n            value: progress.followerCount,\n            requirement: progress.followerRequirement,\n          ),\n          const SizedBox(height: 14),\n          _VerificationProgressLine(\n            key: const Key('creator-verification-coins-progress'),\n            label: 'Eligible Fame Coins received',\n            value: progress.eligibleReceivedCoins,\n            requirement: progress.receivedCoinsRequirement,\n          ),\n          const SizedBox(height: 10),\n          const Text(\n            'Only legitimate cash-backed gifts count. Promotional, referral, owner-QA and self-gifts do not count toward verification.',\n            style: TextStyle(\n              color: Color(0xFF96899C),\n              fontSize: 10,\n              height: 1.4,\n            ),\n          ),\n          if (!verified) ...[\n            const SizedBox(height: 14),\n            SizedBox(\n              width: double.infinity,\n              child: FilledButton(\n                key: const Key('creator-verification-request'),\n                onPressed: canRequest ? onRequest : null,\n                child: Text(pending ? 'Under review' : 'Request verification'),\n              ),\n            ),\n          ],\n        ],\n      ),\n    );\n  }\n}\n\nclass _VerificationProgressLine extends StatelessWidget {\n  const _VerificationProgressLine({\n    required this.label,\n    required this.value,\n    required this.requirement,\n    super.key,\n  });\n\n  final String label;\n  final int value;\n  final int requirement;\n\n  @override\n  Widget build(BuildContext context) {\n    final safeRequirement = requirement <= 0 ? 1 : requirement;\n    final ratio = (value / safeRequirement).clamp(0.0, 1.0).toDouble();\n    final complete = value >= safeRequirement;\n    return Column(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        Row(\n          children: [\n            Expanded(\n              child: Text(\n                label,\n                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),\n              ),\n            ),\n            Text(\n              '\$value / \$requirement',\n              style: TextStyle(\n                color: complete\n                    ? const Color(0xFF72D49B)\n                    : const Color(0xFFC7B8CD),\n                fontSize: 11,\n                fontWeight: FontWeight.w800,\n              ),\n            ),\n          ],\n        ),\n        const SizedBox(height: 7),\n        ClipRRect(\n          borderRadius: BorderRadius.circular(999),\n          child: LinearProgressIndicator(\n            value: ratio,\n            minHeight: 8,\n            backgroundColor: const Color(0xFF2A2030),\n          ),\n        ),\n      ],\n    );\n  }\n}\n`
    source = replaceExact(source, oldCard, newCard, 'verification progress card')
    changed = true
  }

  if (changed) await write(path, source)
}

for (const [path, markers] of [
  [
    'native/flutter_v1/lib/data/fameverse_creator_backend.dart',
    ['FvCreatorVerificationProgress', 'get_creator_verification_progress'],
  ],
  [
    'native/flutter_v1/lib/features/profile/creator_studio_build23.dart',
    [
      "Key('creator-verification-center')",
      "Key('creator-verification-followers-progress')",
      "Key('creator-verification-coins-progress')",
      'Only legitimate cash-backed gifts count.',
      '!_verificationProgress.eligible',
    ],
  ],
]) {
  const source = await read(path)
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`[verification-progress] required marker missing from ${path}: ${marker}`)
    }
  }
}

console.log(
  changed
    ? '[verification-progress] Wired backend-authoritative creator verification progress.'
    : '[verification-progress] Verification progress wiring already present.',
)
