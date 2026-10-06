part of 'stream_host_live_screen.dart';

extension _HostLiveSheets on _NativeHostLiveScreenState {
void _showProfileSheet() {
    unawaited(
      showNativeLiveProfileSheet(
        context: context,
        liveBackend: widget.liveBackend,
        identity: widget.identity,
        roomId: widget.room.id,
        profile: widget.room.host,
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
          height: MediaQuery.sizeOf(context).height * .62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
                      final viewers = participants
                          .where((participant) => !participant.isLocal)
                          .toList();
                      if (viewers.isEmpty) {
                        return const Center(child: Text('No viewers yet.'));
                      }
                      return ListView.separated(
                        itemCount: viewers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final participant = viewers[index];
                          final active =
                              participant.userId == _activeCohostUserId;
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
                              active ? 'Co-hosting now' : 'Viewer',
                            ),
                            trailing: active
                                ? TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      unawaited(_endCohost());
                                    },
                                    child: const Text('End'),
                                  )
                                : _activeCohostUserId == null &&
                                      _pendingInviteUserId == null
                                ? TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      unawaited(_inviteCohost(participant));
                                    },
                                    child: const Text('Invite'),
                                  )
                                : null,
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

  void _showCohostSheet() {
    final call = _call;
    if (call == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17101F),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Co-host',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (_activeCohostUserId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Co-host is live'),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_endCohost());
                      },
                      child: const Text('End co-host'),
                    ),
                  )
                else if (_pendingInviteUserId != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invite pending'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(_cancelInvite());
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                if (_cohostRequests.isNotEmpty) ...[
                  const Text(
                    'Requests',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  ..._cohostRequests.map(
                    (request) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        (request['displayName'] as String?) ??
                            'Fameverse viewer',
                      ),
                      subtitle: const Text('Wants to co-host'),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              unawaited(_declineCohostRequest(request));
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                          IconButton.filled(
                            onPressed: () {
                              Navigator.of(context).pop();
                              unawaited(_acceptCohostRequest(request));
                            },
                            icon: const Icon(Icons.check_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                const Text(
                  'Invite a viewer',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PartialCallStateBuilder<List<CallParticipantState>>(
                    call: call,
                    selector: (state) => state.callParticipants,
                    builder: (context, participants) {
                      final viewers = participants
                          .where((participant) => !participant.isLocal)
                          .toList();
                      if (viewers.isEmpty) {
                        return const Center(
                          child: Text('No viewers to invite yet.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: viewers.length,
                        itemBuilder: (context, index) {
                          final participant = viewers[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              participant.name.isEmpty
                                  ? 'Fameverse viewer'
                                  : participant.name,
                            ),
                            trailing: TextButton(
                              onPressed:
                                  _activeCohostUserId == null &&
                                      _pendingInviteUserId == null
                                  ? () {
                                      Navigator.of(context).pop();
                                      unawaited(_inviteCohost(participant));
                                    }
                                  : null,
                              child: const Text('Invite'),
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
                'Live controls',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-flip'),
                    icon: Icons.cameraswitch_rounded,
                    label: 'Flip',
                    onPressed: _cameraEnabled && !_flipCameraBusy
                        ? () {
                            Navigator.of(context).pop();
                            unawaited(_flipCamera());
                          }
                        : null,
                  ),
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-mic'),
                    icon: _micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: _micEnabled ? 'Mute' : 'Unmute',
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(_toggleMicrophone());
                    },
                  ),
                  FvRoundLiveButton(
                    keyValue: const Key('native-live-camera'),
                    icon: _cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: _cameraEnabled ? 'Camera' : 'Camera on',
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(_toggleCamera());
                    },
                  ),
                  FvRoundLiveButton(
                    icon: Icons.group_add_rounded,
                    label: 'Co-host',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCohostSheet();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                key: const Key('host-share-live-action'),
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_shareLive());
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share live'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
