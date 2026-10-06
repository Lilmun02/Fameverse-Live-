part of 'stream_host_live_screen.dart';

extension _HostLiveSession on _NativeHostLiveScreenState {
Future<void> _connect() async {
    try {
      await StreamVideo.reset(disconnect: true);
      final client = StreamVideo(
        widget.credentials.apiKey,
        user: User.regular(
          userId: widget.credentials.userId,
          name: widget.room.host.displayName,
          image: widget.room.host.avatarUrl,
        ),
        userToken: widget.credentials.userToken,
        options: StreamVideoOptions(
          autoConnect: false,
          audioConfigurationPolicy:
              const AudioConfigurationPolicy.broadcaster(),
        ),
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
        call.setAudioBitrateProfile(SfuAudioBitrateProfile.voiceHighQuality),
        'Could not configure high-quality live audio',
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
        onCohost: (payload) => unawaited(_handleCohostEvent(payload)),
      );

      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        unawaited(
          widget.liveBackend.heartbeatLiveRoom(
            roomId: widget.room.id,
            hostUserId: widget.identity.id,
          ),
        );
      });
      _tapRefresh = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_refreshTapTotal()),
      );

      if (mounted) setState(() => _connecting = false);

      try {
        final stats = await widget.liveBackend.loadGifterStats(
          widget.identity.id,
        );
        if (mounted) setState(() => _gifterLevel = stats.level);
      } catch (_) {}

      try {
        final taps = await widget.liveBackend.loadTapTotal(widget.room.id);
        if (mounted) setState(() => _fameTaps = taps);
      } catch (_) {}
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
    _giftQueue.addAll(fvExpandGiftVisualCombo(playback));
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
    // Renderer completion advances normally; this only prevents a deadlock.
    _giftTimer = Timer(const Duration(seconds: 20), _playNextGift);
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
    FocusManager.instance.primaryFocus?.unfocus();
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
    if (call == null ||
        _connecting ||
        _ending ||
        !_cameraEnabled ||
        _flipCameraBusy) {
      return;
    }

    if (mounted) {
      setState(() => _flipCameraBusy = true);
    } else {
      _flipCameraBusy = true;
    }

    try {
      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');
    } catch (_) {
      if (mounted) _showMessage('Camera flip failed.');
    } finally {
      if (mounted) {
        setState(() => _flipCameraBusy = false);
      } else {
        _flipCameraBusy = false;
      }
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
}
