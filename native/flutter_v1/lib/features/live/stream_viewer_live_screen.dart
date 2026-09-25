import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'native_live_stage.dart';
import 'stream_live_shared.dart';

class NativeViewerLiveScreen extends StatefulWidget {
  const NativeViewerLiveScreen({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    required this.viewerProfile,
    required this.room,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvProfile viewerProfile;
  final FvLiveRoom room;

  @override
  State<NativeViewerLiveScreen> createState() => _NativeViewerLiveScreenState();
}

class _NativeViewerLiveScreenState extends State<NativeViewerLiveScreen> {
  final TextEditingController _comment = TextEditingController();
  final List<FvLiveChatMessage> _chat = [];
  final List<FvGiftPlayback> _giftQueue = [];
  final List<double> _tapBuffer = [];
  final List<Map<String, dynamic>> _tapQueue = [];
  final List<int> _tapBursts = [];
  final Stopwatch _tapClock = Stopwatch();
  Call? _call;
  FvLiveActivitySession? _activity;
  StreamSubscription<CallState>? _callStateSubscription;
  Timer? _tapFlushTimer;
  Timer? _giftTimer;
  FvGiftPlayback? _giftPlayback;
  bool _connecting = true;
  bool _leaving = false;
  bool _walletReady = false;
  bool _giftSending = false;
  bool _tapDraining = false;
  bool _following = false;
  bool _followBusy = false;
  bool _cohostCameraEnabled = true;
  bool _cohostMicEnabled = true;
  int _walletBalance = 0;
  int _gifterLevel = 1;
  int _fameTaps = 0;
  int _localTapCount = 0;
  int _giftSerial = 0;
  String? _accountRole;
  String? _selfCohostState;
  String? _activeCohostUserId;
  Map<String, dynamic>? _incomingInvite;
  String? _error;

  bool get _canRefill => _accountRole == 'owner' || _accountRole == 'admin';
  bool get _selfIsCohost => _activeCohostUserId == widget.identity.id;

  @override
  void initState() {
    super.initState();
    _fameTaps = widget.room.fameTaps;
    _tapClock.start();
    unawaited(_connect());
    unawaited(_loadFollowState());
  }

  Future<void> _loadFollowState() async {
    try {
      final network = await widget.backend.loadFollowNetwork(
        widget.identity.id,
      );
      if (mounted) {
        setState(
          () => _following = network.followingIds.contains(
            widget.room.hostUserId,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _connect() async {
    try {
      final credentials = await widget.liveBackend.issueLiveCredentials(
        roomId: widget.room.id,
        role: 'viewer',
      );
      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        credentials.apiKey,
        user: User.regular(
          userId: credentials.userId,
          name: widget.viewerProfile.displayName,
          image: widget.viewerProfile.avatarUrl,
        ),
        userToken: credentials.userToken,
        options: StreamVideoOptions(autoConnect: false),
      );
      fvRequireSuccess(
        await client.connect(registerPushDevice: false),
        'Could not connect to Stream Video',
      );
      final call = client.makeCall(
        callType: StreamCallType.liveStream(),
        id: credentials.callId,
      );
      _call = call;
      fvRequireSuccess(
        await call.join(
          connectOptions: CallConnectOptions(
            camera: TrackOption.disabled(),
            microphone: TrackOption.disabled(),
          ),
        ),
        'Could not join the livestream',
      );

      _callStateSubscription?.cancel();
      _callStateSubscription = call.state.valueStream.listen((state) {
        if (state.endedAt != null || state.liveEndedAt != null) {
          _exitEndedLive();
        }
      });
      if (call.state.value.endedAt != null ||
          call.state.value.liveEndedAt != null) {
        _exitEndedLive();
        return;
      }

      _activity = widget.liveBackend.openLiveActivity(
        roomId: widget.room.id,
        onComment: _receiveComment,
        onGift: _receiveGift,
        onCohost: (payload) => unawaited(_handleCohostEvent(payload)),
      );
      final results = await Future.wait<dynamic>([
        widget.liveBackend.loadWalletBalance(widget.identity.id),
        widget.liveBackend.loadGifterStats(widget.identity.id),
        widget.backend.loadAccountRole(widget.identity.id),
        widget.liveBackend.loadTapTotal(widget.room.id),
      ]);
      _walletBalance = results[0] as int;
      final stats = results[1] as FvGifterStats;
      _gifterLevel = stats.level;
      _accountRole = results[2] as String?;
      _fameTaps = results[3] as int;
      _walletReady = true;
      _tapFlushTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        _flushTapBuffer();
      });
      if (mounted) setState(() => _connecting = false);
    } catch (error) {
      await _disposeTransport();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not join this live. ${fvFriendlyError(error)}';
      });
    }
  }

  void _receiveComment(Map<String, dynamic> payload) {
    final text = (payload['text'] as String?)?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    setState(() {
      _chat.add(
        FvLiveChatMessage(
          id:
              payload['id']?.toString() ??
              '${DateTime.now().microsecondsSinceEpoch}',
          user: (payload['user'] as String?) ?? 'Fameverse viewer',
          userId: payload['userId'] as String?,
          gifterLevel: (payload['gifterLevel'] as num?)?.toInt() ?? 1,
          text: text.length > 160 ? text.substring(0, 160) : text,
        ),
      );
    });
  }

  void _receiveGift(Map<String, dynamic> payload) {
    final gift = fvGiftById(payload['giftId'] as String?);
    if (gift == null || !mounted) return;
    final quantity = ((payload['quantity'] as num?)?.toInt() ?? 1).clamp(
      1,
      100000,
    );
    final sender = (payload['sender'] as String?) ?? 'Fameverse viewer';
    final level = (payload['gifterLevel'] as num?)?.toInt() ?? 1;
    setState(() {
      _chat.add(
        FvLiveChatMessage(
          id:
              payload['id']?.toString() ??
              '${DateTime.now().microsecondsSinceEpoch}',
          user: sender,
          userId: payload['senderId'] as String?,
          gifterLevel: level,
          kind: 'gift',
          giftId: gift.id,
          quantity: quantity,
          text: '${gift.symbol} sent ${gift.label} ×$quantity',
        ),
      );
    });
    _enqueueGift(
      FvGiftPlayback(gift: gift, quantity: quantity, sender: sender),
    );
  }

  void _enqueueGift(FvGiftPlayback playback) {
    _giftQueue.add(playback);
    if (_giftPlayback == null) _playNextGift();
  }

  void _playNextGift() {
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
    _giftTimer = Timer(
      Duration(milliseconds: next.gift.cinematic ? 6800 : 1800),
      _playNextGift,
    );
  }

  Future<void> _postComment() async {
    final activity = _activity;
    final text = _comment.text.trim();
    if (activity == null || text.isEmpty) return;
    final clean = text.length > 160 ? text.substring(0, 160) : text;
    final id = 'comment-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _chat.add(
        FvLiveChatMessage(
          id: id,
          user: widget.viewerProfile.displayName,
          userId: widget.identity.id,
          gifterLevel: _gifterLevel,
          text: clean,
        ),
      );
      _comment.clear();
    });
    try {
      await activity.send('comment', {
        'id': id,
        'user': widget.viewerProfile.displayName,
        'userId': widget.identity.id,
        'gifterLevel': _gifterLevel,
        'text': clean,
      });
    } catch (_) {
      if (mounted) _showMessage('Comment could not send.');
    }
  }

  Future<bool> _sendGift(FvGiftDefinition gift, int quantity) async {
    if (_giftSending) return false;
    if (!_walletReady) {
      _showMessage('Gift wallet is reconnecting.');
      return false;
    }
    if (widget.room.hostUserId == widget.identity.id) {
      _showMessage('You cannot gift your own live.');
      return false;
    }
    if (quantity < 1 || quantity > 100000) {
      _showMessage('Gift amount must be between 1 and 100,000.');
      return false;
    }
    final total = gift.cost * quantity;
    if (_walletBalance < total) {
      _showMessage(
        _walletBalance == 0
            ? 'No beta test balance is available on this account.'
            : 'Test balance is too low for that gift.',
      );
      return false;
    }
    setState(() => _giftSending = true);
    try {
      final result = await widget.liveBackend.recordGift(
        roomId: widget.room.id,
        giftId: gift.id,
        quantity: quantity,
      );
      final eventId = 'gift-${DateTime.now().microsecondsSinceEpoch}';
      final message = FvLiveChatMessage(
        id: eventId,
        user: widget.viewerProfile.displayName,
        userId: widget.identity.id,
        gifterLevel: result.level,
        kind: 'gift',
        giftId: gift.id,
        quantity: quantity,
        text: '${gift.symbol} sent ${gift.label} ×$quantity',
      );
      if (mounted) {
        setState(() {
          _walletBalance = result.walletBalance;
          _gifterLevel = result.level;
          _chat.add(message);
        });
      }
      await _activity?.send('gift', {
        'id': eventId,
        'sender': widget.viewerProfile.displayName,
        'senderId': widget.identity.id,
        'gifterLevel': result.level,
        'giftId': gift.id,
        'quantity': quantity,
        'totalCoins': total,
      });
      _enqueueGift(
        FvGiftPlayback(
          gift: gift,
          quantity: quantity,
          sender: widget.viewerProfile.displayName,
        ),
      );
      return true;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('insufficient beta coin balance')) {
        _showMessage('Test balance is too low for that gift.');
      } else if (text.contains('beta wallet unavailable')) {
        _showMessage('No beta test balance is available on this account.');
      } else if (text.contains('self gifting')) {
        _showMessage('You cannot gift your own live.');
      } else {
        _showMessage('Gift could not be recorded. Try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _giftSending = false);
    }
  }

  Future<int> _refillWallet() async {
    if (!_canRefill) return _walletBalance;
    try {
      final balance = await widget.liveBackend.refillBetaWallet();
      if (mounted) setState(() => _walletBalance = balance);
      return balance;
    } catch (_) {
      if (mounted) {
        _showMessage('Test-coin refill is limited to owner/admin accounts.');
      }
      return _walletBalance;
    }
  }

  void _showGiftTray() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140D1B),
      builder: (context) => NativeGiftTray(
        coins: _walletBalance,
        canRefill: _canRefill,
        onSend: _sendGift,
        onRefill: _refillWallet,
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _tapStage() {
    if (_connecting || _leaving) return;
    _tapBuffer.add(_tapClock.elapsedMicroseconds / 1000.0);
    final serial = _localTapCount + 1;
    setState(() {
      _localTapCount = serial;
      _tapBursts.add(serial);
      if (_tapBursts.length > 14) _tapBursts.removeAt(0);
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _tapBursts.remove(serial));
    });
    if (_tapBuffer.length >= 100) _flushTapBuffer();
  }

  void _queueTapBuffer() {
    if (_tapBuffer.isEmpty) return;
    final batch = List<double>.from(_tapBuffer);
    _tapBuffer.clear();
    final first = batch.first;
    _tapQueue.add({
      'id': 'tap-${DateTime.now().microsecondsSinceEpoch}',
      'times': batch.map((value) => value - first).toList(),
    });
  }

  void _flushTapBuffer() {
    _queueTapBuffer();
    unawaited(_drainTapQueue());
  }

  Future<void> _drainTapQueue() async {
    if (_tapDraining || _tapQueue.isEmpty) return;
    _tapDraining = true;
    try {
      while (_tapQueue.isNotEmpty) {
        final batch = _tapQueue.first;
        try {
          final result = await widget.liveBackend.recordTapBatch(
            roomId: widget.room.id,
            batchId: batch['id'] as String,
            timestamps: (batch['times'] as List).cast<double>(),
          );
          _tapQueue.removeAt(0);
          if (mounted) {
            setState(() {
              if (result.totalRawTaps > _fameTaps) {
                _fameTaps = result.totalRawTaps;
              }
            });
          }
          if (result.classification == 'rejected') {
            break;
          }
        } catch (_) {
          break;
        }
      }
    } finally {
      _tapDraining = false;
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy || widget.room.hostUserId == widget.identity.id) return;
    setState(() => _followBusy = true);
    final next = !_following;
    try {
      await widget.backend.setFollowing(
        userId: widget.identity.id,
        targetId: widget.room.hostUserId,
        following: next,
      );
      if (mounted) setState(() => _following = next);
    } catch (_) {
      if (mounted) _showMessage('Could not update that connection.');
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _requestCohost() async {
    final activity = _activity;
    if (activity == null ||
        _selfCohostState != null ||
        _activeCohostUserId != null) {
      return;
    }
    setState(() => _selfCohostState = 'requested');
    await activity.send('cohost-request', {
      'viewerId': widget.identity.id,
      'userId': widget.identity.id,
      'displayName': widget.viewerProfile.displayName,
      'avatarUrl': widget.viewerProfile.avatarUrl,
    });
    if (mounted) _showMessage('Co-host request sent.');
  }

  Future<void> _handleCohostEvent(Map<String, dynamic> payload) async {
    final event = payload['_event'] as String?;
    final viewerId = (payload['viewerId'] ?? payload['userId'])?.toString();
    if (viewerId == null) return;

    if (event == 'cohost-active') {
      if (mounted) setState(() => _activeCohostUserId = viewerId);
      if (viewerId == widget.identity.id) await _activateSelfCohost();
      return;
    }
    if (event == 'cohost-ended') {
      if (_activeCohostUserId == viewerId && mounted) {
        setState(() => _activeCohostUserId = null);
      }
      if (viewerId == widget.identity.id) {
        await _deactivateSelfCohost(notify: false);
      }
      return;
    }
    if (viewerId != widget.identity.id) return;

    switch (event) {
      case 'cohost-invite':
        if (_selfCohostState == 'active') break;
        setState(() {
          _incomingInvite = payload;
          _selfCohostState = 'invited';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showInvitePrompt();
        });
        break;
      case 'cohost-invite-cancelled':
        if (mounted) {
          setState(() {
            _incomingInvite = null;
            if (_selfCohostState == 'invited') _selfCohostState = null;
          });
        }
        break;
      case 'cohost-decline':
        if (mounted) {
          setState(() => _selfCohostState = null);
          _showMessage('Co-host request declined.');
        }
        break;
      case 'cohost-accept':
        if (mounted) setState(() => _selfCohostState = 'connecting');
        break;
    }
  }

  void _showInvitePrompt() {
    if (_incomingInvite == null || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Co-host invite'),
        content: Text(
          '${widget.room.host.displayName} invited you to join the live on camera.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(_declineInvite());
            },
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(_acceptInvite());
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvite() async {
    final activity = _activity;
    if (activity == null) return;
    setState(() {
      _incomingInvite = null;
      _selfCohostState = 'connecting';
    });
    await activity.send('cohost-invite-accepted', {
      'viewerId': widget.identity.id,
      'userId': widget.identity.id,
    });
  }

  Future<void> _declineInvite() async {
    final activity = _activity;
    if (activity == null) return;
    setState(() {
      _incomingInvite = null;
      _selfCohostState = null;
    });
    await activity.send('cohost-invite-declined', {
      'viewerId': widget.identity.id,
      'userId': widget.identity.id,
    });
  }

  Future<void> _activateSelfCohost() async {
    final call = _call;
    if (call == null) return;
    for (var attempt = 0; attempt < 12; attempt += 1) {
      if (call.hasPermission(CallPermission.sendAudio) &&
          call.hasPermission(CallPermission.sendVideo)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!call.hasPermission(CallPermission.sendAudio) ||
        !call.hasPermission(CallPermission.sendVideo)) {
      if (mounted) {
        setState(() => _selfCohostState = null);
        _showMessage('Co-host media permission did not arrive. Try again.');
      }
      return;
    }
    try {
      fvRequireSuccess(
        await call.setMicrophoneEnabled(enabled: true),
        'Could not enable co-host microphone',
      );
      fvRequireSuccess(
        await call.setCameraEnabled(enabled: true),
        'Could not enable co-host camera',
      );
      if (mounted) {
        setState(() {
          _selfCohostState = 'active';
          _cohostCameraEnabled = true;
          _cohostMicEnabled = true;
        });
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Co-host camera or microphone could not start.');
      }
    }
  }

  Future<void> _deactivateSelfCohost({bool notify = true}) async {
    final call = _call;
    if (call != null) {
      try {
        await call
            .setCameraEnabled(enabled: false)
            .timeout(const Duration(milliseconds: 900));
      } catch (_) {}
      try {
        await call
            .setMicrophoneEnabled(enabled: false)
            .timeout(const Duration(milliseconds: 900));
      } catch (_) {}
    }
    if (notify) {
      try {
        await _activity
            ?.send('cohost-source-left', {
              'viewerId': widget.identity.id,
              'userId': widget.identity.id,
            })
            .timeout(const Duration(milliseconds: 700));
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _selfCohostState = null;
        if (_activeCohostUserId == widget.identity.id) {
          _activeCohostUserId = null;
        }
      });
    }
  }

  Future<void> _flipCohostCamera() async {
    if (!_selfIsCohost || !_cohostCameraEnabled || _call == null) return;
    try {
      fvRequireSuccess(await _call!.flipCamera(), 'Camera flip failed');
    } catch (_) {
      if (mounted) _showMessage('Camera flip failed.');
    }
  }

  Future<void> _toggleCohostMic() async {
    if (!_selfIsCohost || _call == null) return;
    final next = !_cohostMicEnabled;
    try {
      fvRequireSuccess(
        await _call!.setMicrophoneEnabled(enabled: next),
        'Microphone change failed',
      );
      if (mounted) setState(() => _cohostMicEnabled = next);
    } catch (_) {
      if (mounted) _showMessage('Microphone change failed.');
    }
  }

  Future<void> _toggleCohostCamera() async {
    if (!_selfIsCohost || _call == null) return;
    final next = !_cohostCameraEnabled;
    try {
      fvRequireSuccess(
        await _call!.setCameraEnabled(enabled: next),
        'Camera change failed',
      );
      if (mounted) setState(() => _cohostCameraEnabled = next);
    } catch (_) {
      if (mounted) _showMessage('Camera change failed.');
    }
  }

  Future<void> _shareLive() async {
    final payload =
        'Fameverse Live · ${widget.room.host.displayName} · ${widget.room.title}\nRoom: ${widget.room.id}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (mounted) _showMessage('Live room details copied.');
  }

  void _showProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NativeProfileAvatar(profile: widget.room.host, radius: 42),
              const SizedBox(height: 12),
              Text(
                widget.room.host.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(widget.room.host.handle),
              if (widget.room.host.bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(widget.room.host.bio, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _followBusy ? null : _toggleFollow,
                child: Text(_following ? 'Following' : 'Follow'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewerSheet() {
    final call = _call;
    if (call == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Viewers',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PartialCallStateBuilder<List<CallParticipantState>>(
                    call: call,
                    selector: (state) => state.callParticipants,
                    builder: (context, participants) {
                      if (participants.isEmpty) {
                        return const Center(child: Text('No viewers yet.'));
                      }
                      return ListView.separated(
                        itemCount: participants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          return ListTile(
                            leading: CircleAvatar(
                              foregroundImage:
                                  participant.image != null &&
                                      participant.image!.isNotEmpty
                                  ? NetworkImage(participant.image!)
                                  : null,
                              child: Text(
                                participant.name.isEmpty
                                    ? 'F'
                                    : participant.name[0].toUpperCase(),
                              ),
                            ),
                            title: Text(
                              participant.name.isEmpty
                                  ? 'Fameverse viewer'
                                  : participant.name,
                            ),
                            subtitle: Text(
                              participant.userId == widget.room.hostUserId
                                  ? 'Host'
                                  : participant.userId == _activeCohostUserId
                                  ? 'Co-host'
                                  : 'Viewer',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Live actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (_selfIsCohost) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FvRoundLiveButton(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Flip',
                      onPressed: _cohostCameraEnabled
                          ? () {
                              Navigator.of(context).pop();
                              unawaited(_flipCohostCamera());
                            }
                          : null,
                    ),
                    FvRoundLiveButton(
                      icon: _cohostMicEnabled
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      label: _cohostMicEnabled ? 'Mute' : 'Unmute',
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_toggleCohostMic());
                      },
                    ),
                    FvRoundLiveButton(
                      icon: _cohostCameraEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: _cohostCameraEnabled ? 'Camera' : 'Camera on',
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_toggleCohostCamera());
                      },
                    ),
                    FvRoundLiveButton(
                      icon: Icons.call_end_rounded,
                      label: 'Leave cohost',
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_deactivateSelfCohost());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(_shareLive());
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share live'),
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FvRoundLiveButton(
                      icon: Icons.group_add_rounded,
                      label:
                          _selfCohostState == 'requested' ||
                              _selfCohostState == 'connecting'
                          ? 'Requested'
                          : 'Co-host',
                      onPressed:
                          _selfCohostState == null &&
                              _activeCohostUserId == null
                          ? () {
                              Navigator.of(context).pop();
                              unawaited(_requestCohost());
                            }
                          : null,
                    ),
                    FvRoundLiveButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_shareLive());
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _schedulePop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    _queueTapBuffer();
    unawaited(_drainTapQueue());

    if (_selfIsCohost) {
      try {
        await _activity
            ?.send('cohost-source-left', {
              'viewerId': widget.identity.id,
              'userId': widget.identity.id,
            })
            .timeout(const Duration(milliseconds: 500));
      } catch (_) {}
    }

    _schedulePop();
    unawaited(_disposeTransport());
  }

  void _exitEndedLive() {
    if (_leaving || !mounted) return;
    setState(() => _leaving = true);
    _queueTapBuffer();
    unawaited(_drainTapQueue());
    _schedulePop();
    unawaited(_disposeTransport());
  }

  Future<void> _disposeTransport() async {
    _tapFlushTimer?.cancel();
    _giftTimer?.cancel();
    await _callStateSubscription?.cancel();
    _callStateSubscription = null;
    final activity = _activity;
    _activity = null;
    if (activity != null) {
      try {
        await activity.close();
      } catch (_) {}
    }
    final call = _call;
    _call = null;
    if (call != null) {
      try {
        await call.leave();
      } catch (_) {}
    }
    try {
      await StreamVideo.reset(disconnect: true);
    } catch (_) {}
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _comment.dispose();
    _tapFlushTimer?.cancel();
    _giftTimer?.cancel();
    _callStateSubscription?.cancel();
    _queueTapBuffer();
    unawaited(_drainTapQueue());
    unawaited(_disposeTransport());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    final cohostActive = _activeCohostUserId != null;
    final cohostCameraHeight = (MediaQuery.sizeOf(context).width - 24) / 2;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _tapStage(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (call != null)
                NativeViewerV2Stage(
                  call: call,
                  hostUserId: widget.room.hostUserId,
                  activeCohostUserId: _activeCohostUserId,
                )
              else
                const FvLiveBackground(),
              const FvLiveGradient(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _leaving ? null : _leave,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showProfileSheet,
                            child: NativeProfileAvatar(
                              profile: widget.room.host,
                              radius: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          widget.room.host.handle,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const FvLiveBadge(),
                                  ],
                                ),
                                Text(
                                  widget.room.title,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(
                                    color: Color(0xFFD1C7D7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.room.hostUserId != widget.identity.id)
                            TextButton(
                              onPressed: _followBusy ? null : _toggleFollow,
                              child: Text(_following ? 'Following' : 'Follow'),
                            ),
                          if (call != null)
                            GestureDetector(
                              onTap: _showViewerSheet,
                              child: PartialCallStateBuilder<int>(
                                call: call,
                                selector: (state) =>
                                    state.callParticipants.length,
                                builder: (context, count) => _ViewerStatChip(
                                  icon: Icons.visibility_rounded,
                                  text: '$count',
                                ),
                              ),
                            ),
                          const SizedBox(width: 5),
                          _ViewerStatChip(
                            icon: Icons.local_fire_department_rounded,
                            text: '${_fameTaps + _tapBuffer.length}',
                          ),
                        ],
                      ),
                      if (_connecting || _error != null) ...[
                        const SizedBox(height: 10),
                        if (_connecting)
                          const FvLiveStatusCard(
                            icon: Icons.wifi_tethering_rounded,
                            text: 'Joining live…',
                          ),
                        if (_error != null)
                          FvLiveStatusCard(
                            icon: Icons.error_outline_rounded,
                            text: _error!,
                          ),
                      ],
                      if (cohostActive)
                        SizedBox(height: cohostCameraHeight + 32)
                      else
                        const Spacer(),
                      if (widget.room.goal.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .44),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Goal · ${widget.room.goal}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      if (_selfCohostState == 'requested' ||
                          _selfCohostState == 'connecting')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _selfCohostState == 'connecting'
                                ? 'Connecting co-host camera…'
                                : 'Co-host request pending…',
                            style: const TextStyle(
                              color: Color(0xFFD9C4FF),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: cohostActive ? 250 : 220,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: FvLiveChatList(messages: _chat),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FvLiveCommentComposer(
                              controller: _comment,
                              hintText: 'Say something...',
                            ),
                          ),
                          const SizedBox(width: 5),
                          IconButton.filled(
                            onPressed: _postComment,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF6F35C5),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                            tooltip: 'Send comment',
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            key: const Key('viewer-gift-button'),
                            onPressed: _walletReady ? _showGiftTray : null,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF211529),
                              foregroundColor: const Color(0xFFFFC65A),
                              side: const BorderSide(color: Color(0xFF4B365B)),
                            ),
                            icon: const Icon(Icons.card_giftcard_rounded),
                            tooltip: 'Gifts',
                          ),
                          const SizedBox(width: 4),
                          FvFameActionButton(
                            onPressed: _showFMenu,
                            tooltip: 'Live actions',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_giftPlayback != null)
                NativeGiftOverlay(
                  key: ValueKey('viewer-gift-$_giftSerial'),
                  playback: _giftPlayback!,
                ),
              ..._tapBursts.map(
                (serial) => Positioned(
                  right: 16 + (serial % 3) * 16,
                  bottom: 86,
                  child: IgnorePointer(
                    child: _TapBurstParticle(serial: serial),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapBurstParticle extends StatelessWidget {
  const _TapBurstParticle({required this.serial});

  final int serial;

  @override
  Widget build(BuildContext context) {
    final symbol = serial.isEven ? '🔥' : 'F';
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOut,
      builder: (context, progress, child) {
        return Opacity(
          opacity: (1 - progress).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -118 * progress),
            child: Transform.scale(
              scale: .82 + (.28 * (1 - progress)),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        symbol,
        style: TextStyle(
          color: symbol == 'F' ? const Color(0xFFB96BFF) : null,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
        ),
      ),
    );
  }
}

class _ViewerStatChip extends StatelessWidget {
  const _ViewerStatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
