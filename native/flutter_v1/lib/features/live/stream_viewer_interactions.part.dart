part of 'stream_viewer_live_screen.dart';

extension _ViewerLiveInteractions on _NativeViewerLiveScreenState {
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
    final call = _call;
    if (!_selfIsCohost ||
        !_cohostCameraEnabled ||
        call == null ||
        _cohostFlipBusy) {
      return;
    }

    if (mounted) {
      setState(() => _cohostFlipBusy = true);
    } else {
      _cohostFlipBusy = true;
    }

    try {
      fvRequireSuccess(await call.flipCamera(), 'Camera flip failed');
    } catch (_) {
      if (mounted) _showMessage('Camera flip failed.');
    } finally {
      if (mounted) {
        setState(() => _cohostFlipBusy = false);
      } else {
        _cohostFlipBusy = false;
      }
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
}
