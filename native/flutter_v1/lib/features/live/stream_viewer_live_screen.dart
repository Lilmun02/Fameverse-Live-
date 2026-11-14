import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../profile/fame_coin_store_screen.dart';
import 'native_live_components.dart';
import 'native_gift_receipt_gate.dart';
import 'native_live_profile_sheet.dart';
import 'native_live_rankings.dart';
import 'native_live_stage.dart';
import 'stream_live_shared.dart';

class NativeViewerLiveScreen extends StatefulWidget {
  static Future<void> _lastTransportCleanup = Future<void>.value();

  const NativeViewerLiveScreen({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    required this.viewerProfile,
    required this.room,
    this.onLiveJoined,
    this.onExitFeed,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvProfile viewerProfile;
  final FvLiveRoom room;
  final VoidCallback? onLiveJoined;
  final VoidCallback? onExitFeed;

  @override
  State<NativeViewerLiveScreen> createState() => _NativeViewerLiveScreenState();
}

class _NativeViewerLiveScreenState extends State<NativeViewerLiveScreen> {
  final TextEditingController _comment = TextEditingController();
  final List<FvLiveChatMessage> _chat = [];
  final List<FvGiftPlayback> _giftQueue = [];
  final FvGiftReceiptGate _giftEventGate 