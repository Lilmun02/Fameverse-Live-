import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'stream_host_live_screen.dart' as base;

/// Build 23 owner/admin host wrapper.
///
/// Regression contract:
/// - ordinary hosts keep the approved Live surface unchanged;
/// - owner/admin test accounts retain the in-Live QA gift tray while hosting;
/// - host QA gifts use `record_beta_gift`, never the public cash-earning path;
/// - public self-gifting stays blocked by `send_fameverse_gift`.
class NativeHostLiveScreen extends StatefulWidget {
  const NativeHostLiveScreen({
    required this.liveBackend,
    required this.identity,
    required this.room,
    required this.credentials,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvLiveRoom room;
  final FvLiveCredentials credentials;

  @override
  State<NativeHostLiveScreen> createState() => _NativeHostLiveScreenState();
}

class _NativeHostLiveScreenState extends State<NativeHostLiveScreen> {
  bool _qaGiftAllowed = false;
  bool _giftBusy = false;
  int _walletBalance = 0;
  int _testCoins = 0;
  int _gifterLevel = 1;
  int _giftSerial = 0;
  final List<FvGiftPlayback> _giftQueue = <FvGiftPlayback>[];
  FvGiftPlayback? _giftPlayback;
  Timer? _giftTimer;
  FvLiveActivitySession? _qaActivity;

  @override
  void initState() {
    super.initState();
    unawaited(_loadQaGiftAccess());
  }

  Map<String, dynamic> _firstRpcRow(dynamic data) {
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
  }

  Future<void> _loadQaGiftAccess() async {
    try {
      final row = await Supabase.instance.client
          .from('account_roles')
          .select('role')
          .eq('user_id', widget.identity.id)
          .maybeSingle();
      final role = (row?['role'] as String?)?.trim().toLowerCase();
      final allowed = role == 'owner' || role == 'admin';
      if (!allowed) return;

      if (!mounted) return;
      _qaActivity ??= widget.liveBackend.openLiveActivity(
        roomId: widget.room.id,
      );
      setState(() => _qaGiftAllowed = true);

      try {
        final funding = await widget.liveBackend.loadCoinFundingBreakdown();
        if (mounted) {
          setState(() {
            _walletBalance = funding.totalCoins;
            _testCoins = funding.testCoins;
          });
        }
      } catch (_) {}

      try {
        final stats = await widget.liveBackend.loadGifterStats(
          widget.identity.id,
        );
        if (mounted) setState(() => _gifterLevel = stats.level);
      } catch (_) {}
    } catch (_) {
      // Fail closed. A role lookup failure must never expose owner QA controls.
    }
  }

  Future<FvCoinFundingBreakdown> _refillQaWallet() async {
    if (!_qaGiftAllowed) {
      return FvCoinFundingBreakdown(
        realCoins: 0,
        testCoins: _testCoins,
        totalCoins: _walletBalance,
      );
    }
    try {
      await widget.liveBackend.refillBetaWallet();
      final funding = await widget.liveBackend.loadCoinFundingBreakdown();
      if (mounted) {
        setState(() {
          _walletBalance = funding.totalCoins;
          _testCoins = funding.testCoins;
        });
      }
      return funding;
    } catch (_) {
      if (mounted) {
        _message('Test-coin refill is limited to owner/admin accounts.');
      }
      return FvCoinFundingBreakdown(
        realCoins: 0,
        testCoins: _testCoins,
        totalCoins: _walletBalance,
      );
    }
  }

  Future<void> _broadcastQaGiftReceipt(Map<String, dynamic> payload) async {
    final activity = _qaActivity;
    if (activity == null) {
      if (mounted) {
        _message('Gift recorded. Live animation sync is reconnecting.');
      }
      return;
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        await activity.send('gift', payload);
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 180 * (attempt + 1)),
          );
        }
      }
    }

    if (mounted) {
      _message('Gift recorded. Live animation sync is reconnecting.');
    }
  }

  Future<bool> _sendQaGift(
    FvGiftDefinition gift,
    int quantity,
    String _fundingMode,
  ) async {
    if (!_qaGiftAllowed || _giftBusy) return false;
    if (quantity < 1 || quantity > 100000) {
      _message('Gift amount must be between 1 and 100,000.');
      return false;
    }

    setState(() => _giftBusy = true);
    try {
      final raw = await Supabase.instance.client.rpc(
        'record_beta_gift',
        params: <String, dynamic>{
          'p_room_id': widget.room.id,
          'p_gift_id': gift.id,
          'p_quantity': quantity,
        },
      );
      final row = _firstRpcRow(raw);
      if (row.isEmpty) throw StateError('gift-result-missing');

      final nextBalance = (row['wallet_balance'] as num?)?.toInt() ?? 0;
      final nextLevel = (row['level'] as num?)?.toInt() ?? _gifterLevel;
      final eventId = 'host-qa-gift-${DateTime.now().microsecondsSinceEpoch}';
      final playback = FvGiftPlayback(
        gift: gift,
        quantity: quantity,
        sender: widget.room.host.displayName,
      );

      if (mounted) {
        setState(() {
          _walletBalance = nextBalance;
          _testCoins = (_testCoins - (gift.cost * quantity))
              .clamp(0, nextBalance)
              .toInt();
          _gifterLevel = nextLevel;
        });
      }
      _enqueueQaGift(playback);

      await _broadcastQaGiftReceipt(<String, dynamic>{
        'id': eventId,
        'sender': widget.room.host.displayName,
        'senderId': widget.identity.id,
        'gifterLevel': nextLevel,
        'giftId': gift.id,
        'quantity': quantity,
        'totalCoins': gift.cost * quantity,
        'qaHostPreview': true,
      });

      return true;
    } catch (error) {
      final value = error.toString().toLowerCase();
      if (value.contains('insufficient promotional') ||
          value.contains('insufficient funded')) {
        _message('Test balance is too low for that gift.');
      } else if (value.contains('owner or admin')) {
        _message('Owner/admin QA gift access is required.');
      } else {
        _message('QA gift could not be recorded.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _giftBusy = false);
    }
  }

  void _enqueueQaGift(FvGiftPlayback playback) {
    _giftQueue.addAll(fvExpandGiftVisualCombo(playback));
    if (_giftPlayback == null) _playNextQaGift();
  }

  void _playNextQaGift() {
    _giftTimer?.cancel();
    if (_giftQueue.isEmpty) {
      if (mounted) setState(() => _giftPlayback = null);
      return;
    }
    final next = _giftQueue.removeAt(0);
    if (mounted) {
      setState(() {
        _giftPlayback = next;
        _giftSerial += 1;
      });
    }
    _giftTimer = Timer(const Duration(seconds: 20), _playNextQaGift);
  }

  void _showGiftTray() {
    if (!_qaGiftAllowed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140D1B),
      builder: (context) => NativeGiftTray(
        coins: _walletBalance,
        realCoins: 0,
        testCoins: _testCoins,
        canRefill: true,
        onSend: _sendQaGift,
        onRefill: _refillQaWallet,
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _giftTimer?.cancel();
    _giftQueue.clear();
    final activity = _qaActivity;
    _qaActivity = null;
    if (activity != null) unawaited(activity.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        base.NativeHostLiveScreen(
          liveBackend: widget.liveBackend,
          identity: widget.identity,
          room: widget.room,
          credentials: widget.credentials,
          onGiftPressed: _qaGiftAllowed ? _showGiftTray : null,
          giftButtonEnabled: !_giftBusy,
        ),
        if (_giftPlayback != null)
          NativeGiftOverlay(
            key: ValueKey<String>('owner-host-qa-gift-$_giftSerial'),
            playback: _giftPlayback!,
            onFinished: _playNextQaGift,
          ),
      ],
    );
  }
}
