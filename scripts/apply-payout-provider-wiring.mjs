import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)
const path = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart'

const read = (file) => readFile(new URL(file, root), 'utf8')
const write = (file, content) => writeFile(new URL(file, root), content, 'utf8')

function replaceExact(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[payout-provider-patch] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[payout-provider-patch] ${label}: expected source block was not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let source = await read(path)
let changed = false

const oldProcessMethod = `  Future<void> _beginPayoutProcessing(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final raw = await _client.rpc(
        'begin_creator_payout_processing',
        params: {'p_payout_id': payoutId},
      );
      final details = _firstRow(raw);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payout ready for provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: \${_money(_int(details['amount_cents']))}'),
              const SizedBox(height: 6),
              Text('Provider: \${details['payout_provider'] ?? 'Not set'}'),
              const SizedBox(height: 6),
              Text('Recipient: \${details['payout_recipient'] ?? 'Not set'}'),
              const SizedBox(height: 12),
              const Text(
                'Send the real payment with the provider. Do not mark Paid until the provider confirms success.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      await _refresh();
    } catch (_) {
      _message('Could not begin payout processing.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
`

const newProcessMethods = `  Future<void> _beginPayoutProcessing(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'process-creator-payout',
        body: {
          'payout_id': payoutId,
          'expected_environment': 'sandbox',
        },
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok = response.status >= 200 &&
          response.status < 300 &&
          data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_submission_failed';
        throw StateError(code);
      }
      final providerStatus =
          data['provider_status']?.toString() ?? 'PENDING';
      _message('PayPal sandbox payout submitted: \$providerStatus.');
      await _refresh();
    } catch (error) {
      final text = error.toString();
      final code = text.contains('paypal_credentials_missing')
          ? 'PayPal sandbox credentials are not configured.'
          : text.contains('paypal_environment_mismatch')
              ? 'PayPal payout environment does not match sandbox QA.'
              : text.contains('paypal_auth_failed')
                  ? 'PayPal sandbox authentication failed.'
                  : text.contains('paypal_payout_failed')
                      ? 'PayPal rejected the sandbox payout.'
                      : text.contains('payout_not_processable')
                          ? 'This payout is not approved for processing.'
                          : 'Provider submission failed.';
      _message(code);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncPayoutStatus(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'sync-creator-payout',
        body: {
          'payout_id': payoutId,
          'expected_environment': 'sandbox',
        },
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok = response.status >= 200 &&
          response.status < 300 &&
          data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_sync_failed';
        throw StateError(code);
      }
      final fameverseStatus =
          data['fameverse_status']?.toString() ?? 'processing';
      final providerStatus =
          data['provider_status']?.toString() ?? 'PENDING';
      _message(
        'PayPal status: \$providerStatus · Fameverse: \$fameverseStatus.',
      );
      await _refresh();
    } catch (error) {
      final text = error.toString();
      final message = text.contains('provider_batch_missing')
          ? 'This payout has no PayPal batch ID. Submit it to PayPal first.'
          : text.contains('paypal_auth_failed')
              ? 'PayPal sandbox authentication failed.'
              : text.contains('paypal_status_failed')
                  ? 'PayPal could not return the payout status.'
                  : 'Could not sync this payout with PayPal.';
      _message(message);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
`

if (!source.includes("'process-creator-payout'")) {
  source = replaceExact(
    source,
    oldProcessMethod,
    newProcessMethods,
    'provider payout submission and sync methods',
  )
  changed = true
}

if (!source.includes('onSync: () => _syncPayoutStatus(payout)')) {
  source = replaceExact(
    source,
    `                        onProcess: () => _beginPayoutProcessing(payout),
                        onPaid: () => _reviewPayout(payout, 'paid'),
                        onFailed: () => _reviewPayout(payout, 'failed'),`,
    `                        onProcess: () => _beginPayoutProcessing(payout),
                        onSync: () => _syncPayoutStatus(payout),`,
    'payout card provider callbacks',
  )
  changed = true
}

if (!source.includes('required this.onSync,')) {
  source = replaceExact(
    source,
    `    required this.onProcess,
    required this.onPaid,
    required this.onFailed,`,
    `    required this.onProcess,
    required this.onSync,`,
    'payout card constructor callback',
  )
  source = replaceExact(
    source,
    `  final VoidCallback onProcess;
  final VoidCallback onPaid;
  final VoidCallback onFailed;`,
    `  final VoidCallback onProcess;
  final VoidCallback onSync;`,
    'payout card callback fields',
  )
  changed = true
}

if (!source.includes("label: const Text('Send with PayPal sandbox')")) {
  source = replaceExact(
    source,
    `              label: const Text('Begin processing'),`,
    `              label: const Text('Send with PayPal sandbox'),`,
    'approved payout provider action label',
  )
  changed = true
}

if (!source.includes("label: const Text('Sync PayPal status')")) {
  source = replaceExact(
    source,
    `          else if (status == 'processing')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('owner-payout-mark-paid'),
                  onPressed: busy ? null : onPaid,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Mark paid'),
                ),
                TextButton(
                  onPressed: busy ? null : onFailed,
                  child: const Text('Mark failed'),
                ),
              ],
            ),`,
    `          else if (status == 'processing')
            FilledButton.icon(
              key: const Key('owner-payout-sync-provider'),
              onPressed: busy ? null : onSync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sync PayPal status'),
            ),`,
    'processing payout provider status action',
  )
  changed = true
}

for (const required of [
  "'process-creator-payout'",
  "'sync-creator-payout'",
  "'expected_environment': 'sandbox'",
  "Key('owner-payout-sync-provider')",
  "Text('Send with PayPal sandbox')",
]) {
  if (!source.includes(required)) {
    throw new Error(`[payout-provider-patch] required provider wiring missing: ${required}`)
  }
}

if (source.includes("key: const Key('owner-payout-mark-paid')")) {
  throw new Error('[payout-provider-patch] manual paid button still exists in primary payout path')
}

if (changed) await write(path, source)

console.log(
  changed
    ? '[payout-provider-patch] Wired owner payouts to PayPal provider Edge Functions.'
    : '[payout-provider-patch] Provider payout wiring already present.',
)
