part of 'stream_host_live_screen.dart';

extension _HostLiveCohost on _NativeHostLiveScreenState {
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
            (item) =>
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
        if (_pendingInviteUserId == viewerId) await _grantCohost(viewerId);
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
          (item) =>
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
          (item) =>
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
}
