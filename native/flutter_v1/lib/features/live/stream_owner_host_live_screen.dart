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
  int _gifterLevel = 1;
  int _giftSerial = 0;
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

      final results = await Future.wait<dynamic>([
        widget.liveBackend.loadWalletBalance(widget.identity.id),
        widget.liveBackend.loadGifterStats(widget.identity.id),
      ]);
      final stats = results[1] as FvGifterStats;
      if (!mounted) return;

      _qaActivity ??= widget.liveBackend.openLiveActivity(
        roomId: widget.room.id,
      );
      setState(() {
        _qaGiftAllowed = true;
        _walletBalance = results[0] as int;
        _gifterLevel = stats.level;
      });
    } catch (_) {
      // Fail closed. A role lookup failure must never expose owner QA controls.
    }
  }

  Future<int> _refillQaWallet() async {
    if (!_qaGiftAllowed) return _walletBalance;
    try {
      final balance = await widget.liveBackend.refillBetaWallet();
      if (mounted) setState(() => _walletBalance = balance);
      return balance;
    } catch (_) {
      if (mounted) {
        _message('Test-coin refill is limited to owner/admin accounts.');
      }
      return _walletBalance;
    }
  }

  Future<bool> _sendQaGift(FvGiftDefinition gift, int quantity) async {
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
          _gifterLevel = nextLevel;
          _giftPlayback = playback;
          _giftSerial += 1;
        });
      }

      await _qaActivity?.send('gift', <String, dynamic>{
        'id': eventId,
        'sender': widget.room.host.displayName,
        'senderId': widget.identity.id,
        'gifterLevel': nextLevel,
        'giftId': gift.id,
        'quantity': quantity,
        'totalCoins': gift.cost * quantity,
        'qaHostPreview': true,
      });

      _giftTimer?.cancel();
      _giftTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => _giftPlayback = null);
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

  void _showGiftTray() {
    if (!_qaGiftAllowed) return;
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140D1B),
      builder: (context) => NativeGiftTray(
        coins: _walletBalance,
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
            onFinished: () {
              _giftTimer?.cancel();
              if (mounted) setState(() => _giftPlayback = null);
            },
          ),
      ],
    );
  }
}
