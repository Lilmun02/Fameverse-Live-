part of 'stream_viewer_live_screen.dart';

extension _ViewerLiveView on _NativeViewerLiveScreenState {
  Widget buildView(BuildContext context) {
    final call = _call;
    final cohostActive = _activeCohostUserId != null;
    final cohostCameraHeight = (MediaQuery.sizeOf(context).width - 24) / 2;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => _tapStage(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (call != null)
                NativeViewerV2Stage(
                  call: call,
                  hostUserId: widget.room.hostUserId,
                  activeCohostUserId: _activeCohostUserId,
                )
              else
                const FvLiveBackground(),
              const FvLiveGradient(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _leaving ? null : _leave,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showProfileSheet,
                            child: NativeProfileAvatar(
                              profile: widget.room.host,
                              radius: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: FittedBox(
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
                          if (widget.room.hostUserId != widget.identity.id)
                            TextButton(
                              onPressed: _followBusy ? null : _toggleFollow,
                              child: Text(_following ? 'Following' : 'Follow'),
                            ),
                          if (call != null)
                            GestureDetector(
                              onTap: _showViewerSheet,
                              child: PartialCallStateBuilder<int>(
                                call: call,
                                selector: (state) =>
                                    state.callParticipants.length,
                                builder: (context, count) => _ViewerStatChip(
                                  icon: Icons.visibility_rounded,
                                  text: '$count',
                                ),
                              ),
                            ),
                          const SizedBox(width: 5),
                          _ViewerStatChip(
                            icon: Icons.local_fire_department_rounded,
                            text: '${_fameTaps + _tapBuffer.length}',
                          ),
                          const SizedBox(width: 3),
                          IconButton(
                            key: const Key('viewer-live-rankings-button'),
                            onPressed: () =>
                                unawaited(showNativeLiveRankings(context)),
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: Color(0xFFFFC75A),
                            ),
                            tooltip: 'Rankings',
                          ),
                        ],
                      ),
                      if (_connecting || _error != null) ...[
                        const SizedBox(height: 10),
                        if (_connecting)
                          const FvLiveStatusCard(
                            icon: Icons.wifi_tethering_rounded,
                            text: 'Joining live…',
                          ),
                        if (_error != null)
                          FvLiveStatusCard(
                            icon: Icons.error_outline_rounded,
                            text: _error!,
                          ),
                      ],
                      if (cohostActive)
                        SizedBox(height: cohostCameraHeight + 32)
                      else
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
                      if (_selfCohostState == 'requested' ||
                          _selfCohostState == 'connecting')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _selfCohostState == 'connecting'
                                ? 'Connecting co-host camera…'
                                : 'Co-host request pending…',
                            style: const TextStyle(
                              color: Color(0xFFD9C4FF),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: cohostActive ? 250 : 220,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: FvLiveChatList(messages: _chat),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FvLiveCommentComposer(
                              controller: _comment,
                              hintText: 'Say something...',
                            ),
                          ),
                          const SizedBox(width: 5),
                          IconButton.filled(
                            onPressed: _postComment,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF6F35C5),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                            tooltip: 'Send comment',
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            key: const Key('viewer-gift-button'),
                            onPressed: _walletReady ? _showGiftTray : null,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF211529),
                              foregroundColor: const Color(0xFFFFC65A),
                              side: const BorderSide(color: Color(0xFF4B365B)),
                            ),
                            icon: const Icon(Icons.card_giftcard_rounded),
                            tooltip: 'Gifts',
                          ),
                          const SizedBox(width: 4),
                          FvFameActionButton(
                            onPressed: _showFMenu,
                            tooltip: 'Live actions',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ..._tapBursts.map(
                (serial) => Positioned(
                  right: 16 + (serial % 3) * 16,
                  bottom: 86,
                  child: IgnorePointer(
                    child: _TapBurstParticle(serial: serial),
                  ),
                ),
              ),
              if (_giftPlayback != null)
                NativeGiftOverlay(
                  key: ValueKey('viewer-gift-$_giftSerial'),
                  playback: _giftPlayback!,
                  onFinished: _playNextGift,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
