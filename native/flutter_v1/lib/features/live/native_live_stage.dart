import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'stream_live_shared.dart';

// Keeps the display awake only while an active native Live stage is mounted.
class _FvLiveWakeLock extends StatefulWidget {
  const _FvLiveWakeLock({required this.child});

  final Widget child;

  @override
  State<_FvLiveWakeLock> createState() => _FvLiveWakeLockState();
}

class _FvLiveWakeLockState extends State<_FvLiveWakeLock> {
  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Approved V2 contract:
// - solo = full-canvas camera
// - active co-host = two equal square camera boxes side-by-side
// - never convert co-host into tall stacked rectangles
class NativeHostV2Stage extends StatelessWidget {
  const NativeHostV2Stage({
    required this.call,
    required this.cameraEnabled,
    required this.activeCohostUserId,
    super.key,
  });

  final Call call;
  final bool cameraEnabled;
  final String? activeCohostUserId;

  @override
  Widget build(BuildContext context) {
    return _FvLiveWakeLock(
      child: PartialCallStateBuilder<List<CallParticipantState>>(
        call: call,
        selector: (CallState state) => state.callParticipants,
        builder:
            (BuildContext context, List<CallParticipantState> participants) {
              CallParticipantState? host;
              CallParticipantState? cohost;
              for (final participant in participants) {
                if (participant.isLocal) host = participant;
                if (participant.userId == activeCohostUserId) {
                  cohost = participant;
                }
              }

              if (activeCohostUserId == null) {
                return _V2ParticipantSurface(
                  call: call,
                  participant: host,
                  videoEnabled:
                      cameraEnabled && (host?.isVideoEnabled ?? false),
                  cameraOff: true,
                );
              }

              return _V2CohostStage(
                left: _V2ParticipantSurface(
                  call: call,
                  participant: host,
                  videoEnabled:
                      cameraEnabled && (host?.isVideoEnabled ?? false),
                  cameraOff: true,
                  label: 'Host',
                ),
                right: _V2ParticipantSurface(
                  call: call,
                  participant: cohost,
                  videoEnabled: cohost?.isVideoEnabled ?? false,
                  label: cohost?.name.isNotEmpty == true
                      ? cohost!.name
                      : 'Co-host',
                ),
              );
            },
      ),
    );
  }
}

class NativeViewerV2Stage extends StatelessWidget {
  const NativeViewerV2Stage({
    required this.call,
    required this.hostUserId,
    required this.activeCohostUserId,
    super.key,
  });

  final Call call;
  final String hostUserId;
  final String? activeCohostUserId;

  @override
  Widget build(BuildContext context) {
    return _FvLiveWakeLock(
      child: PartialCallStateBuilder<List<CallParticipantState>>(
        call: call,
        selector: (CallState state) => state.callParticipants,
        builder:
            (BuildContext context, List<CallParticipantState> participants) {
              CallParticipantState? host;
              CallParticipantState? cohost;
              for (final participant in participants) {
                if (participant.userId == hostUserId) host = participant;
                if (participant.userId == activeCohostUserId) {
                  cohost = participant;
                }
              }

              if (activeCohostUserId == null) {
                return _V2ParticipantSurface(
                  call: call,
                  participant: host,
                  videoEnabled: host?.isVideoEnabled ?? false,
                );
              }

              return _V2CohostStage(
                left: _V2ParticipantSurface(
                  call: call,
                  participant: host,
                  videoEnabled: host?.isVideoEnabled ?? false,
                  label: host?.name.isNotEmpty == true ? host!.name : 'Host',
                ),
                right: _V2ParticipantSurface(
                  call: call,
                  participant: cohost,
                  videoEnabled: cohost?.isVideoEnabled ?? false,
                  label: cohost?.name.isNotEmpty == true
                      ? cohost!.name
                      : 'Co-host',
                ),
              );
            },
      ),
    );
  }
}

class _V2CohostStage extends StatelessWidget {
  const _V2CohostStage({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const FvLiveBackground(),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 70, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: left,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _V2ParticipantSurface extends StatelessWidget {
  const _V2ParticipantSurface({
    required this.call,
    required this.participant,
    required this.videoEnabled,
    this.cameraOff = false,
    this.label,
  });

  final Call call;
  final CallParticipantState? participant;
  final bool videoEnabled;
  final bool cameraOff;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final participant = this.participant;
    if (participant == null || !videoEnabled) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FvLiveBackground(
            icon: cameraOff ? Icons.videocam_off_rounded : Icons.person_rounded,
          ),
          if (label != null) _V2StageLabel(text: label!),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        StreamCallParticipant(
          call: call,
          participant: participant,
          videoFit: VideoFit.cover,
          showConnectionQualityIndicator: false,
          showParticipantLabel: false,
          showSpeakerBorder: false,
        ),
        if (label != null) _V2StageLabel(text: label!),
      ],
    );
  }
}

class _V2StageLabel extends StatelessWidget {
  const _V2StageLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      bottom: 8,
      child: IgnorePointer(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .46),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
