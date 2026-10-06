import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'native_live_profile_sheet.dart';
import 'native_live_rankings.dart';
import 'native_live_stage.dart';
import 'stream_live_shared.dart';
part 'stream_host_session.part.dart';
part 'stream_host_cohost.part.dart';
part 'stream_host_sheets.part.dart';
part 'stream_host_view.part.dart';
part 'stream_host_widgets.part.dart';


class NativeHostLiveScreen extends StatefulWidget {
  const NativeHostLiveScreen({
    required this.liveBackend,
    required this.identity,
    required this.room,
    required this.credentials,
    this.onGiftPressed,
    this.giftButtonEnabled = true,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvLiveRoom room;
  final FvLiveCredentials credentials;
  final VoidCallback? onGiftPressed;
  final bool giftButtonEnabled;

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
  bool _flipCameraBusy = false;
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
    return _HostLiveView(this).buildView(context);
  }
}
