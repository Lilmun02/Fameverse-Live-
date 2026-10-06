import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
part 'owner_control_center_dialogs.part.dart';
part 'owner_control_center_view.part.dart';
part 'owner_control_center_review_cards.part.dart';
part 'owner_control_center_widgets.part.dart';


class Build23OwnerControlCenterScreen extends StatefulWidget {
  const Build23OwnerControlCenterScreen({this.onOpenCreatorStudio, super.key});

  final VoidCallback? onOpenCreatorStudio;

  @override
  State<Build23OwnerControlCenterScreen> createState() =>
      _Build23OwnerControlCenterScreenState();
}

class _Build23OwnerControlCenterScreenState
    extends State<Build23OwnerControlCenterScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _summary = const {};
  Map<String, dynamic> _wallet = const {};
  List<Map<String, dynamic>> _payouts = const [];
  List<Map<String, dynamic>> _verificationQueue = const [];

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _firstRow(dynamic value) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    dynamic summaryResult;
    dynamic walletResult;
    dynamic payoutResult;
    dynamic verificationResult;
    final failures = <String>[];

    try {
      summaryResult = await _client.rpc('get_owner_finance_control_summary');
    } catch (_) {
      failures.add('finance summary');
    }
    try {
      walletResult = await _client.rpc('get_my_coin_funding_breakdown');
    } catch (_) {
      failures.add('coin balances');
    }
    try {
      payoutResult = await _client.rpc(
        'get_creator_payout_moderation_queue_v3',
        params: const {'p_limit': 50},
      );
    } catch (_) {
      failures.add('payout review');
    }
    try {
      verificationResult = await _client.rpc(
        'get_creator_verification_moderation_queue',
        params: const {'p_limit': 50},
      );
    } catch (_) {
      failures.add('verification review');
    }

    if (!mounted) return;
    setState(() {
      if (summaryResult != null) _summary = _firstRow(summaryResult);
      if (walletResult != null) _wallet = _firstRow(walletResult);
      if (payoutResult != null) _payouts = _rows(payoutResult);
      if (verificationResult != null) {
        _verificationQueue = _rows(verificationResult);
      }
      _loading = false;
      _error = failures.isEmpty
          ? null
          : 'Some owner data could not refresh: ${failures.join(', ')}.';
    });
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _openPayPal() async {
    final uri = Uri.parse('https://www.paypal.com/myaccount/money/');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) _message('Could not open PayPal.');
  }

  Future<void> _reviewVerification(
    Map<String, dynamic> request,
    String status,
  ) async {
    if (_busy) return;
    final userId = request['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'review_creator_verification',
        params: {
          'p_user_id': userId,
          'p_status': status,
          'p_public_note': status == 'verified'
              ? 'Creator verification approved by Fameverse review.'
              : status == 'needs_info'
              ? 'More information is required before verification can be approved.'
              : 'Verification request was not approved.',
        },
      );
      _message('Verification updated to ${status.replaceAll('_', ' ')}.');
      await _refresh();
    } catch (_) {
      _message('Could not update creator verification.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewPayout(Map<String, dynamic> payout, String status) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    final title = switch (status) {
      'approved' => 'Approve payout',
      'held' => 'Hold payout',
      'rejected' => 'Reject payout',
      'paid' => 'Mark payout paid',
      'failed' => 'Mark payout failed',
      _ => 'Update payout',
    };
    final result = await _OwnerControlDialogs(this).askPayoutReview(
      title: title,
      body: status == 'paid'
          ? 'Only mark this paid after the real provider payment has succeeded. Fameverse will debit the creator earnings ledger when this is confirmed.'
          : 'This action changes the payout moderation status. It does not move money through PayPal by itself.',
      action: status == 'paid' ? 'Confirm paid' : 'Confirm',
      requireReference: status == 'paid',
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'review_creator_payout',
        params: {
          'p_payout_id': payoutId,
          'p_status': status,
          'p_moderation_note': result.note,
          'p_external_reference': result.reference,
        },
      );
      _message('Payout status updated to ${status.replaceAll('_', ' ')}.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('verified creator required')) {
        _message(
          'This creator must be verified before a payout can be marked paid.',
        );
      } else {
        _message('Could not update that payout.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _beginPayoutProcessing(Map<String, dynamic> payout) async {
    if (_busy) return;
    final payoutId = payout['payout_id']?.toString();
    if (payoutId == null || payoutId.isEmpty) return;
    final environment =
        payout['payout_environment']?.toString().toLowerCase() == 'live'
        ? 'live'
        : 'sandbox';
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'process-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': environment},
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok =
          response.status >= 200 && response.status < 300 && data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_submission_failed';
        throw StateError(code);
      }
      final providerStatus = data['provider_status']?.toString() ?? 'PENDING';
      _message('PayPal $environment payout submitted: $providerStatus.');
      await _refresh();
    } catch (error) {
      final text = error.toString();
      final code = text.contains('paypal_credentials_missing')
          ? 'PayPal sandbox credentials are not configured.'
          : text.contains('paypal_environment_mismatch')
          ? 'PayPal payout environment does not match this request.'
          : text.contains('paypal_auth_failed')
          ? 'PayPal sandbox authentication failed.'
          : text.contains('paypal_payout_failed')
          ? 'PayPal rejected the sandbox payout.'
          : text.contains('paypal_submission_unknown') ||
                text.contains('paypal_batch_id_missing')
          ? 'PayPal submission is still unresolved. The creator funds remain reserved; use Recover PayPal submission again after refresh.'
          : text.contains('payout_not_processable')
          ? 'This payout is not approved for processing or recovery.'
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
    final environment =
        payout['payout_environment']?.toString().toLowerCase() == 'live'
        ? 'live'
        : 'sandbox';
    setState(() => _busy = true);
    try {
      final response = await _client.functions.invoke(
        'sync-creator-payout',
        body: {'payout_id': payoutId, 'expected_environment': environment},
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final ok =
          response.status >= 200 && response.status < 300 && data['ok'] == true;
      if (!ok) {
        final code = data['error']?.toString() ?? 'provider_sync_failed';
        throw StateError(code);
      }
      final fameverseStatus =
          data['fameverse_status']?.toString() ?? 'processing';
      final providerStatus = data['provider_status']?.toString() ?? 'PENDING';
      _message('PayPal status: $providerStatus · Fameverse: $fameverseStatus.');
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

  Future<void> _recordSettledReserve() async {
    if (_busy) return;
    final cents = await _OwnerControlDialogs(this).askDollars(
      title: 'Record Reward Funds',
      body:
          'Enter real business cash that has already settled and that you are intentionally setting aside for Fameverse rewards. This records the amount inside Fameverse; it does not transfer money from PayPal.',
      action: 'Record funds',
    );
    if (cents == null) return;
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_allocate_reward_reserve',
        params: {
          'p_amount_cents': cents,
          'p_note': 'Owner recorded settled reward funds',
        },
      );
      _message('Reward Reserve funds recorded.');
      await _refresh();
    } catch (_) {
      _message('Could not record those Reward Reserve funds.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _issueCashRewardCoins() async {
    if (_busy) return;
    final coinsController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Cash-Backed Fame Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash-Backed Fame Coins use real money from the Reward Reserve and can create real creator earnings. Promo Fame Coins are separate and do not use this reserve.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: coinsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cash-Backed Fame Coins',
                prefixIcon: Icon(Icons.toll_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(coinsController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    coinsController.dispose();
    if (text == null) return;
    final coins = int.tryParse(text.trim()) ?? 0;
    if (coins <= 0) {
      _message('Enter a valid cash-backed coin amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _client.rpc(
        'owner_issue_cash_backed_reward_coins',
        params: {
          'p_coins': coins,
          'p_note': 'Owner created cash-backed reward coins',
        },
      );
      _message('Cash-Backed Fame Coins created.');
      await _refresh();
    } catch (error) {
      final text = error.toString().toLowerCase();
      _message(
        text.contains('insufficient funded cash reward reserve')
            ? 'Not enough Reward Reserve funds for that many cash-backed coins.'
            : 'Could not create Cash-Backed Fame Coins.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OwnerControlCenterView(this).buildView(context);
  }
}
