import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'native_live_stage.dart';
import 'stream_live_shared.dart';

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
  final TextEditingController _comment = TextEditingController();
  final List<FvLiveChatMessage> _chat = <FvLiveChatMessage>[];
  final List<Map<String, dynamic>> _cohostRequests = <Map<String, dynamic>>[];
  final List<FvGiftPlayback> _giftQueue = <FvGiftPlayback>[];

  Call? _call;
  FvLiveActivitySession? _activity;
  Timer? _heartbeat;
  Timer? _tapRefresh;
  Timer? _giftTimer;
  FvGiftPlayback? _giftPlayback;

  bool _connecting = true;
  bool _ending = false;
  bool _ended = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  int _fameTaps = 0;
  int _gifterLevel = 1;
  int _giftSerial = 0;
  String? _activeCohostUserId;
  String? _pendingInviteUserId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fameTaps = widget.room.fameTaps;
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        widget.credentials.apiKey,
        user: User.regular(
          userId: widget.credentials.userId,
          name: widget.room.host.displayName,
        ),
        userToken: widget.credentials.userToken,
        options: StreamVideoOptions(autoConnect: false),
      );
      fvRequireSuccess(
        await client.connect(registerPushDevice: false),
        'Could not connect to Stream Video',
      );

      final call = client.makeCall(
        callType: StreamCallType.liveStream(),
        id: widget.credentials.callId,
      );
      _call = call;
      fvRequireSuccess(
        await call.getOrCreate(
          members: <MemberRequest>[
            MemberRequest(userId: widget.credentials.userId, role: 'host'),
          ],
        ),
        'Could not create the livestream',
      );
      fvRequireSuccess(
        await call.join(
          connectOptions: CallConnectOptions(
            camera: TrackOption.enabled(),
            microphone: TrackOption.enabled(),
            cameraFacingMode: FacingMode.user,
          ),
          hintHighScaleLivestreamPublisher: true,
        ),
        'Could not join the livestream',
      );
      fvRequireSuccess(await call.goLive(), 'Could not start the livestream');

      _activity = widget.liveBackend.openLiveActivity(
        roomId: widget.room.id,
        onComment: _receiveComment,
        onGift: _receiveGift,
        onCohost: (Map<String, dynamic> payload) {
          unawaited(_handleCohostEvent(payload));
        },
      );

      final stats = await widget.liveBackend.loadGifterStats(
        widget.identity.id,
      );
      final taps = await widget.liveBackend.loadTapTotal(widget.room.id);
      _gifterLevel = stats.level;
      _fameTaps = taps;

      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        unawaited(
          widget.liveBackend.heartbeatLiveRoom(
            roomId: widget.room.id,
            hostUserId: widget.identity.id,
          ),
        );
      });
      _tapRefresh = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_refreshTapTotal());
      });

      if (mounted) setState(() => _connecting = false);
    } catch (error) {
      await _markRoomEnded();
      await _disposeTransport();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error =
            'Could not start the live broadcast. ${fvFriendlyError(error)}';
      });
    }
  }

  Future<void> _refreshTapTotal() async {
    try {
      final taps = await widget.liveBackend.loadTapTotal(widget.room.id);
      if (mounted && taps != _fameTaps) setState(() => _fameTaps = taps);
    } catch (_) {}
  }

  void _receiveComment(Map<String, dynamic> payload) {
    final raw = (payload['text'] as String?)?.trim() ?? '';
    if (!mounted || raw.isEmpty) return;
    final text = raw.length > 160 ? raw.substring(0, 160) : raw;
    setState(() {
      _chat.add(
        FvLiveChatMessage(
          id:
              payload['id']?.toString() ??
              '${DateTime.now().microsecondsSinceEpoch}',
          user: (payload['user'] as String?) ?? 'Fameverse viewer',
          userId: payload['userId'] as String?,
          gifterLevel: (payload['gifterLevel'] as num?)?.toInt() ?? 1,
          text: text,
        ),
      );
    });
  }

  void _receiveGift(Map<String, dynamic> payload) {
    final gift = fvGiftById(payload['giftId'] as String?);
    if (!mounted || gift == null) return;
    final rawQuantity = (payload['quantity'] as num?)?.toInt() ?? 1;
    final quantity = rawQuantity.clamp(1, 100000);
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
    final raw = _comment.text.trim();
    if (activity == null || raw.isEmpty) return;
    final text = raw.length > 160 ? raw.substring(0, 160) : raw;
    final id = 'comment-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _chat.add(
        FvLiveChatMessage(
          id: id,
          user: widget.room.host.displayName,
          userId: widget.identity.id,
          gifterLevel: _gifterLevel,
          text: text,
        ),
      );
      _comment.clear();
    });
    try {
      await activity.send('comment', <String, dynamic>{
        'id': id,
        'user': widget.room.host.displayName,
        'userId': widget.identity.id,
        'gifterLevel': _gifterLevel,
        'text': text,
      });
    } catch (_) {
      if (mounted) _showMessage('Comment could not send.');
    }
  }

  Future<void> _flipCamera() async {
    final call = _call;
    if (call == null || _connecting || _ending || !_cameraEnabled) return;
    try {
      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');
    } catch (_) {
      if (mounted) _showMessage('Camera flip failed.');
    }
  }

  Future<void> _toggleMicrophone() async {
    final call = _call;
    if (call == null || _connecting || _ending) return;
    final next = !_micEnabled;
    try {
      fvRequireSuccess(
        await call.setMicrophoneEnabled(enabled: next),
        'Microphone change failed',
      );
      if (mounted) setState(() => _micEnabled = next);
    } catch (_) {
      if (mounted) _showMessage('Microphone change failed.');
    }
  }

  Future<void> _toggleCamera() async {
    final call = _call;
    if (call == null || _connecting || _ending) return;
    final next = !_cameraEnabled;
    try {
      fvRequireSuccess(
        await call.setCameraEnabled(enabled: next),
        'Camera change failed',
      );
      if (mounted) setState(() => _cameraEnabled = next);
    } catch (_) {
      if (mounted) _showMessage('Camera change failed.');
    }
  }

  Future<void> _handleCohostEvent(Map<String, dynamic> payload) async {
    final event = payload['_event'] as String?;
    final viewerId = (payload['viewerId'] ?? payload['userId'])?.toString();
    if (viewerId == null || viewerId == widget.identity.id) return;

    switch (event) {
      case 'cohost-request':
        if (_activeCohostUserId != null || _pendingInviteUserId == viewerId) {
          return;
        }
        if (!mounted) return;
        setState(() {
          _cohostRequests.removeWhere(
            (Map<String, dynamic> item) =>
                (item['viewerId'] ?? item['userId'])?.toString() == viewerId,
          );
          _cohostRequests.insert(0, <String, dynamic>{
            ...payload,
            'viewerId': viewerId,
            'displayName': payload['displayName'] ?? 'Fameverse viewer',
          });
          if (_cohostRequests.length > 12) _cohostRequests.removeLast();
        });
        break;
      case 'cohost-invite-accepted':
        if (_pendingInviteUserId != viewerId) return;
        await _grantCohost(viewerId);
        break;
      case 'cohost-invite-declined':
      case 'cohost-invite-cancelled':
        if (_pendingInviteUserId == viewerId && mounted) {
          setState(() => _pendingInviteUserId = null);
        }
        break;
      case 'cohost-source-left':
        if (_activeCohostUserId == viewerId) {
          await _endCohost(notify: true);
        }
        break;
      case 'cohost-ended':
        if (_activeCohostUserId == viewerId && mounted) {
          setState(() => _activeCohostUserId = null);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _inviteCohost(CallParticipantState participant) async {
    final activity = _activity;
    if (activity == null ||
        _activeCohostUserId != null ||
        _pendingInviteUserId != null ||
        participant.isLocal) {
      return;
    }
    setState(() => _pendingInviteUserId = participant.userId);
    await activity.send('cohost-invite', <String, dynamic>{
      'inviteId': 'invite-${DateTime.now().microsecondsSinceEpoch}',
      'viewerId': participant.userId,
      'userId': participant.userId,
      'displayName': participant.name,
    });
    if (mounted) _showMessage('Co-host invite sent to ${participant.name}.');
  }

  Future<void> _acceptCohostRequest(Map<String, dynamic> request) async {
    final viewerId = (request['viewerId'] ?? request['userId'])?.toString();
    if (viewerId == null || _activeCohostUserId != null) return;
    if (mounted) {
      setState(() {
        _cohostRequests.removeWhere(
          (Map<String, dynamic> item) =>
              (item['viewerId'] ?? item['userId'])?.toString() == viewerId,
        );
      });
    }
    await _grantCohost(viewerId, acceptedRequest: true);
  }

  Future<void> _declineCohostRequest(Map<String, dynamic> request) async {
    final viewerId = (request['viewerId'] ?? request['userId'])?.toString();
    final activity = _activity;
    if (viewerId == null || activity == null) return;
    if (mounted) {
      setState(() {
        _cohostRequests.removeWhere(
          (Map<String, dynamic> item) =>
              (item['viewerId'] ?? item['userId'])?.toString() == viewerId,
        );
      });
    }
    await activity.send('cohost-decline', <String, dynamic>{
      'viewerId': viewerId,
      'userId': viewerId,
    });
  }

  Future<void> _grantCohost(
    String viewerId, {
    bool acceptedRequest = false,
  }) async {
    final call = _call;
    final activity = _activity;
    if (call == null || activity == null) return;
    try {
      fvRequireSuccess(
        await call.grantPermissions(
          userId: viewerId,
          permissions: const <CallPermission>[
            CallPermission.sendAudio,
            CallPermission.sendVideo,
          ],
        ),
        'Could not grant co-host media permissions',
      );
      if (acceptedRequest) {
        await activity.send('cohost-accept', <String, dynamic>{
          'viewerId': viewerId,
          'userId': viewerId,
        });
      }
      await activity.send('cohost-active', <String, dynamic>{
        'viewerId': viewerId,
        'userId': viewerId,
      });
      if (mounted) {
        setState(() {
          _activeCohostUserId = viewerId;
          _pendingInviteUserId = null;
        });
      }
    } catch (_) {
      if (mounted) _showMessage('Co-host could not start.');
    }
  }

  Future<void> _endCohost({bool notify = true}) async {
    final userId = _activeCohostUserId;
    if (userId == null) return;
    final call = _call;
    if (call != null) {
      try {
        await call.revokePermissions(
          userId: userId,
          permissions: const <CallPermission>[
            CallPermission.sendAudio,
            CallPermission.sendVideo,
          ],
        );
      } catch (_) {}
    }
    if (notify) {
      try {
        await _activity?.send('cohost-ended', <String, dynamic>{
          'viewerId': userId,
          'userId': userId,
        });
      } catch (_) {}
    }
    if (mounted) setState(() => _activeCohostUserId = null);
  }

  Future<void> _cancelInvite() async {
    final userId = _pendingInviteUserId;
    final activity = _activity;
    if (userId == null || activity == null) return;
    await activity.send('cohost-invite-cancelled', <String, dynamic>{
      'viewerId': userId,
      'userId': userId,
    });
    if (mounted) setState(() => _pendingInviteUserId = null);
  }

  Future<void> _shareLive() async {
    final payload =
        'Fameverse Live · ${widget.room.host.displayName} · ${widget.room.title}\nRoom: ${widget.room.id}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (mounted) _showMessage('Live room details copied.');
  }

  Future<void> _markRoomEnded() async {
    if (_ended) return;
    _ended = true;
    _heartbeat?.cancel();
    _tapRefresh?.cancel();
    try {
      await widget.liveBackend.endLiveRoom(
        roomId: widget.room.id,
        hostUserId: widget.identity.id,
      );
    } catch (_) {}
  }

  Future<void> _disposeTransport() async {
    _heartbeat?.cancel();
    _tapRefresh?.cancel();
    _giftTimer?.cancel();
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

  Future<void> _endLive() async {
    if (_ending) return;
    setState(() => _ending = true);
    await _endCohost();
    final call = _call;
    if (call != null) {
      try {
        await call.stopLive();
      } catch (_) {}
      try {
        await call.end(reason: 'host_ended');
      } catch (_) {}
    }
    await _markRoomEnded();
    await _disposeTransport();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17101F),
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
              if (widget.room.host.bio.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(widget.room.host.bio, textAlign: TextAlign.center),
              ],
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
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Viewers',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PartialCallStateBuilder<List<CallParticipantState>>(
                    call: call,
                    selector: (CallState state) => state.callParticipants,
                    builder:
                        (
                          BuildContext context,
                          List<CallParticipantState> participants,
                        ) {
                          final viewers = participants
                              .where((p) => !p.isLocal)
                              .toList();
                          if (viewers.isEmpty) {
                            return const Center(child: Text('No viewers yet.'));
                          }
                          return ListView.separated(
                            itemCount: viewers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final participant = viewers[index];
                              final isActive =
                                  participant.userId == _activeCohostUserId;
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    participant.name.isEmpty
                                        ? 'F'
                                        : participant.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  participant.name.isEmpty
                                      ? 'Fameverse viewer'
                                      : participant.name,
                                ),
                                subtitle: Text(
                                  isActive ? 'Co-hosting now' : 'Viewer',
                                ),
                                trailing: isActive
                                    ? TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          unawaited(_endCohost());
                                        },
                                        child: const Text('End'),
                                      )
                                    : _activeCohostUserId == null &&
                                          _pendingInviteUserId == null
                                    ? TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          unawaited(_inviteCohost(participant));
                                        },
                                        child: const Text('Invite'),
                                      )
                                    : null,
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

  void _showCohostSheet() {
    final call = _call;
    if (call == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Co-host',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (_activeCohostUserId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Co-host is live'),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_endCohost());
                      },
                      child: const Text('End co-host'),
                    ),
                  )
                else if (_pendingInviteUserId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invite pending'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_cancelInvite());
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                if (_cohostRequests.isNotEmpty) ...<Widget>[
                  const Text(
                    'Requests',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  ..._cohostRequests.map(
                    (Map<String, dynamic> request) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        (request['displayName'] as String?) ??
                            'Fameverse viewer',
                      ),
                      subtitle: const Text('Wants to co-host'),
                      trailing: Wrap(
                        children: <Widget>[
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              unawaited(_declineCohostRequest(request));
                            },
                            icon: const Icon(Icons.close),
                          ),
                          IconButton.filled(
                            onPressed: () {
                              Navigator.of(context).pop();
                              unawaited(_acceptCohostRequest(request));
                            },
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                const Text(
                  'Invite a viewer',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PartialCallStateBuilder<List<CallParticipantState>>(
                    call: call,
                    selector: (CallState state) => state.callParticipants,
                    builder:
                        (
                          BuildContext context,
                          List<CallParticipantState> participants,
                        ) {
                          final viewers = participants
                              .where((p) => !p.isLocal)
                              .toList();
                          if (viewers.isEmpty) {
                            return const Center(
                              child: Text('No viewers to invite yet.'),
                            );
                          }
                          return ListView.builder(
                            itemCount: viewers.length,
                            itemBuilder: (BuildContext context, int index) {
                              final participant = viewers[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  participant.name.isEmpty
                                      ? 'Fameverse viewer'
                                      : participant.name,
                                ),
                                trailing: TextButton(
                                  onPressed:
                                      _activeCohostUserId == null &&
                                          _pendingInviteUserId == null
                                      ? () {
                                          Navigator.of(context).pop();
                                          unawaited(_inviteCohost(participant));
                                        }
                                      : null,
                                  child: const Text('Invite'),
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
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Live controls',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-flip'),
                    icon: Icons.cameraswitch_rounded,
                    label: 'Flip',
                    onPressed: _cameraEnabled
                        ? () {
                            Navigator.of(context).pop();
                            unawaited(_flipCamera());
                          }
                        : null,
                  ),
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-mic'),
                    icon: _micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: _micEnabled ? 'Mute' : 'Unmute',
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(_toggleMicrophone());
                    },
                  ),
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-camera'),
                    icon: _cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: _cameraEnabled ? 'Camera' : 'Camera on',
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(_toggleCamera());
                    },
                  ),
                  FvRoundLiveButton(
                    icon: Icons.group_add_rounded,
                    label: 'Co-host',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCohostSheet();
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

  @override
  void dispose() {
    _comment.dispose();
    _heartbeat?.cancel();
    _tapRefresh?.cancel();
    _giftTimer?.cancel();
    if (!_ended) unawaited(_markRoomEnded());
    unawaited(_disposeTransport());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    return PopScope(
      canPop: _ended,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (!didPop && !_ending) unawaited(_endLive());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (call != null)
              NativeHostV2Stage(
                call: call,
                cameraEnabled: _cameraEnabled,
                activeCohostUserId: _activeCohostUserId,
              )
            else
              const FvLiveBackground(icon: Icons.videocam_off_rounded),
            const FvLiveGradient(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: _showProfileSheet,
                          child: NativeProfileAvatar(
                            profile: widget.room.host,
                            radius: 18,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Flexible(
                                    child: FittedBox(
                                      key: const Key('host-live-handle'),
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
                        if (call != null)
                          GestureDetector(
                            onTap: _showViewerSheet,
                            child: PartialCallStateBuilder<int>(
                              call: call,
                              selector: (CallState state) =>
                                  state.callParticipants.length,
                              builder: (BuildContext context, int count) =>
                                  _StatChip(
                                    icon: Icons.visibility_rounded,
                                    text: '${count > 0 ? count - 1 : 0}',
                                  ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        _StatChip(
                          icon: Icons.local_fire_department_rounded,
                          text: '$_fameTaps',
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('native-end-live'),
                          onPressed: _ending ? null : _endLive,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD5284D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: Text(_ending ? 'Ending…' : 'End'),
                        ),
                      ],
                    ),
                    if (_connecting || _error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      if (_connecting)
                        const FvLiveStatusCard(
                          icon: Icons.wifi_tethering_rounded,
                          text: 'Connecting your broadcast…',
                        ),
                      if (_error != null)
                        FvLiveStatusCard(
                          icon: Icons.error_outline_rounded,
                          text: _error!,
                        ),
                    ],
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
                    SizedBox(
                      height: 220,
                      child: SingleChildScrollView(
                        reverse: true,
                        child: FvLiveChatList(messages: _chat),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            maxLength: 160,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => unawaited(_postComment()),
                            decoration: const InputDecoration(
                              hintText: 'Say something...',
                              counterText: '',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: _postComment,
                          icon: const Icon(Icons.send_rounded),
                          tooltip: 'Send comment',
                        ),
                        IconButton.filledTonal(
                          onPressed: _shareLive,
                          icon: const Icon(Icons.ios_share_rounded),
                          tooltip: 'Share',
                        ),
                        IconButton.filled(
                          key: const Key('host-f-menu-button'),
                          onPressed: _showFMenu,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF8E4DFF),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Text(
                            'F',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          tooltip: 'Live controls',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_giftPlayback != null)
              NativeGiftOverlay(
                key: ValueKey<String>('host-gift-$_giftSerial'),
                playback: _giftPlayback!,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13),
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
