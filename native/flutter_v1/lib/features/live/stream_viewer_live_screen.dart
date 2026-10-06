import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../profile/fame_coin_store_screen.dart';
import 'native_live_components.dart';
import 'native_live_profile_sheet.dart';
import 'native_live_rankings.dart';
import 'native_live_stage.dart';
import 'stream_live_shared.dart';
part 'stream_viewer_session.part.dart';
part 'stream_viewer_interactions.part.dart';
part 'stream_viewer_sheets.part.dart';
part 'stream_viewer_view.part.dart';
part 'stream_viewer_widgets.part.dart';


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
  bool _cohostFlipBusy = false;
  bool _cohostMicEnabled = true;
  int _walletBalance = 0;
  int _realCoins = 0;
  int _testCoins = 0;
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
    return _ViewerLiveView(this).buildView(context);
  }
}
