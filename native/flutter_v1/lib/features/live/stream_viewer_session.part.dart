part of 'stream_viewer_live_screen.dart';

extension _ViewerLiveSession on _NativeViewerLiveScreenState {
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
        options: StreamVideoOptions(
          autoConnect: false,
          audioConfigurationPolicy: const AudioConfigurationPolicy.viewer(),
        ),
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
        call.setAudioBitrateProfile(SfuAudioBitrateProfile.voiceHighQuality),
        'Could not configure high-quality live audio',
      );
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
      _walletReady = true;
      _tapFlushTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        _flushTapBuffer();
      });
      if (mounted) setState(() => _connecting = false);
      unawaited(_hydrateViewerState());
    } catch (error) {
      await _disposeTransport();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Could not join this live. ${fvFriendlyError(error)}';
      });
    }
  }

  Future<void> _hydrateViewerState() async {
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
    } catch (_) {
      try {
        final balance = await widget.liveBackend.loadWalletBalance(
          widget.identity.id,
        );
        if (mounted) {
          setState(() {
            _walletBalance = balance;
            _walletReady = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _walletReady = true);
      }
    }

    try {
      final stats = await widget.liveBackend.loadGifterStats(
        widget.identity.id,
      );
      if (mounted) setState(() => _gifterLevel = stats.level);
    } catch (_) {}

    try {
      final role = await widget.backend.loadAccountRole(widget.identity.id);
      if (mounted) setState(() => _accountRole = role);
    } catch (_) {}

    try {
      final taps = await widget.liveBackend.loadTapTotal(widget.room.id);
      if (mounted) setState(() => _fameTaps = taps);
    } catch (_) {}
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
    FocusManager.instance.primaryFocus?.unfocus();
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

  Future<void> _broadcastGiftReceipt(Map<String, dynamic> payload) async {
    final activity = _activity;
    if (activity == null) {
      if (mounted) {
        _showMessage('Gift sent. Live animation sync is reconnecting.');
      }
      return;
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        await activity.send('gift', payload);
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 180 * (attempt + 1)),
          );
        }
      }
    }

    if (mounted) {
      _showMessage('Gift sent. Live animation sync is reconnecting.');
    }
  }

  Future<bool> _sendGift(
    FvGiftDefinition gift,
    int quantity,
    String fundingMode,
  ) async {
    if (_giftSending) return false;
    FocusManager.instance.primaryFocus?.unfocus();
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
            ? 'Your Fame Coin balance is empty.'
            : 'Your Fame Coin balance is too low for that gift.',
      );
      return false;
    }
    setState(() => _giftSending = true);
    try {
      final result = await widget.liveBackend.recordGift(
        roomId: widget.room.id,
        giftId: gift.id,
        quantity: quantity,
        fundingMode: fundingMode,
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
          _realCoins = (_realCoins - result.realCoinsSpent)
              .clamp(0, result.walletBalance)
              .toInt();
          _testCoins = (_testCoins - result.testCoinsSpent)
              .clamp(0, result.walletBalance)
              .toInt();
          _gifterLevel = result.level;
          _chat.add(message);
        });
      }
      _enqueueGift(
        FvGiftPlayback(
          gift: gift,
          quantity: quantity,
          sender: widget.viewerProfile.displayName,
        ),
      );
      await _broadcastGiftReceipt(<String, dynamic>{
        'id': eventId,
        'sender': widget.viewerProfile.displayName,
        'senderId': widget.identity.id,
        'gifterLevel': result.level,
        'giftId': gift.id,
        'quantity': quantity,
        'totalCoins': total,
      });
      return true;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('insufficient real fame coins')) {
        _showMessage('Your Real Coin balance is too low for that gift.');
      } else if (text.contains('insufficient test fame coins') ||
          text.contains('insufficient promotional')) {
        _showMessage('Your Test Coin balance is too low for that gift.');
      } else if (text.contains('insufficient beta coin balance')) {
        _showMessage('Your Fame Coin balance is too low for that gift.');
      } else if (text.contains('beta wallet unavailable')) {
        _showMessage('Your Fame Coin wallet is unavailable right now.');
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

  Future<FvCoinFundingBreakdown> _refillWallet() async {
    if (!_canRefill) {
      return FvCoinFundingBreakdown(
        realCoins: _realCoins,
        testCoins: _testCoins,
        totalCoins: _walletBalance,
      );
    }
    try {
      await widget.liveBackend.refillBetaWallet();
      final funding = await widget.liveBackend.loadCoinFundingBreakdown();
      if (mounted) {
        setState(() {
          _walletBalance = funding.totalCoins;
          _realCoins = funding.realCoins;
          _testCoins = funding.testCoins;
        });
      }
      return funding;
    } catch (_) {
      if (mounted) {
        _showMessage('Test-coin refill is limited to owner/admin accounts.');
      }
      return FvCoinFundingBreakdown(
        realCoins: _realCoins,
        testCoins: _testCoins,
        totalCoins: _walletBalance,
      );
    }
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
