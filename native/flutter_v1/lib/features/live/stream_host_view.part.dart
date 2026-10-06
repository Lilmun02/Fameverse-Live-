part of 'stream_host_live_screen.dart';

extension _HostLiveView on _NativeHostLiveScreenState {
  Widget buildView(BuildContext context) {
    final call = _call;
    final cohostActive = _activeCohostUserId != null;
    final cohostCameraHeight = (MediaQuery.sizeOf(context).width - 24) / 2;

    return PopScope(
      canPop: _ended,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_ending) unawaited(_endLive());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (call != null)
              NativeHostV2Stage(
                call: call,
                cameraEnabled: _cameraEnabled,
                activeCohostUserId: _activeCohostUserId,
              )
            else
              const FvLiveBackground(icon: Icons.videocam_off_rounded),
            const FvLiveGradient(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!cohostActive) ...[
                      const Center(child: _FameverseLiveWordmark()),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _showProfileSheet,
                          child: _NeonHostAvatar(profile: widget.room.host),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.room.host.displayName,
                                      key: const Key('host-live-handle'),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const FvLiveBadge(),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.room.title,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Color(0xFFD6CADC),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  key: const Key('host-live-rankings-left'),
                                  onPressed: () => unawaited(
                                    showNativeLiveRankings(context),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFFFC75A),
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                      vertical: 1,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 12,
                                  ),
                                  label: const Text(
                                    'Rankings',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (call != null)
                          GestureDetector(
                            onTap: _showViewerSheet,
                            child: PartialCallStateBuilder<int>(
                              call: call,
                              selector: (state) =>
                                  state.callParticipants.length,
                              builder: (context, count) => _LiveStatsPill(
                                viewerCount: count > 0 ? count - 1 : 0,
                                fameTaps: _fameTaps,
                              ),
                            ),
                          )
                        else
                          _LiveStatsPill(viewerCount: 0, fameTaps: _fameTaps),
                        const SizedBox(width: 6),
                        FilledButton(
                          key: const Key('native-end-live'),
                          onPressed: _ending ? null : _endLive,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE62952),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(_ending ? 'Ending…' : 'End'),
                        ),
                      ],
                    ),
                    if (_connecting || _error != null) ...[
                      const SizedBox(height: 9),
                      if (_connecting)
                        const FvLiveStatusCard(
                          icon: Icons.wifi_tethering_rounded,
                          text: 'Connecting your broadcast…',
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
                          border: Border.all(color: const Color(0x556F35C5)),
                        ),
                        child: Text(
                          'Goal · ${widget.room.goal}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    SizedBox(
                      height: cohostActive ? 230 : 245,
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
                        const SizedBox(width: 6),
                        IconButton.filled(
                          key: const Key('host-live-send-comment'),
                          onPressed: _postComment,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF6F35C5),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFAD73FF)),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          tooltip: 'Send comment',
                        ),
                        if (widget.onGiftPressed != null) ...[
                          const SizedBox(width: 4),
                          IconButton.filled(
                            key: const Key('owner-host-gift-button'),
                            onPressed: widget.giftButtonEnabled
                                ? widget.onGiftPressed
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF211529),
                              foregroundColor: const Color(0xFFFFC65A),
                              side: const BorderSide(color: Color(0xFF4B365B)),
                            ),
                            icon: const Icon(Icons.card_giftcard_rounded),
                            tooltip: 'Gifts',
                          ),
                        ],
                        const SizedBox(width: 4),
                        FvFameActionButton(
                          keyValue: const Key('host-f-menu-button'),
                          onPressed: _showFMenu,
                          tooltip: 'Live controls',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_giftPlayback != null)
              NativeGiftOverlay(
                key: ValueKey<String>('host-gift-$_giftSerial'),
                playback: _giftPlayback!,
                onFinished: _playNextGift,
              ),
          ],
        ),
      ),
    );
  }
}
