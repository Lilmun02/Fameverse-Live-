import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'native_gift_receipt_gate.dart';
import 'native_live_profile_sheet.dart';
import 'native_live_rankings.dart';
import 'native_live_stage.dart';
import 'fv_host_viewer_arrival_tracker.dart';
import 'stream_live_shared.dart';

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
  final FvGiftReceiptGate _giftEventGate = FvGiftRecei