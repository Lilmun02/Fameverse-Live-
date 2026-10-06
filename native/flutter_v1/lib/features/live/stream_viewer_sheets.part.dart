part of 'stream_viewer_live_screen.dart';

extension _ViewerLiveSheets on _NativeViewerLiveScreenState {
void _showProfileSheet() {
    unawaited(
      showNativeLiveProfileSheet(
        context: context,
        liveBackend: widget.liveBackend,
        backend: widget.backend,
        identity: widget.identity,
        roomId: widget.room.id,
        profile: widget.room.host,
        onFollowingChanged: (following) {
          if (mounted) setState(() => _following = following);
        },
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
                      onPressed: _cohostCameraEnabled && !_cohostFlipBusy
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

Future<void> _openCoinStore() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FameCoinStoreScreen(
          userId: widget.identity.id,
          onBalanceChanged: (balance) {
            if (!mounted) return;
            setState(() {
              _walletBalance = balance;
              _walletReady = true;
            });
          },
        ),
      ),
    );
    try {
      final funding = await widget.liveBackend.loadCoinFundingBreakdown();
      if (mounted) {
        setState(() {
          _walletBalance = funding.totalCoins;
          _realCoins = funding.realCoins;
          _testCoins = funding.testCoins;
          _walletReady = true;
        });
      }
    } catch (_) {}
  }

  void _showGiftTray() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF140D1B),
      builder: (sheetContext) => NativeGiftTray(
        coins: _walletBalance,
        realCoins: _realCoins,
        testCoins: _testCoins,
        canRefill: _canRefill,
        onSend: _sendGift,
        onRefill: _refillWallet,
        onBuyCoins: () {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_openCoinStore());
          });
        },
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

}
