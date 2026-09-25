import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void fvRequireSuccess<T>(Result<T> result, String message) {
  if (result.isFailure) {
    throw StateError('$message: ${result.getErrorOrNull()}');
  }
}

String fvFriendlyError(Object error) {
  final text = error.toString();
  if (text.contains('stream-not-configured')) {
    return 'Stream Video credentials are not configured yet.';
  }
  if (text.toLowerCase().contains('permission')) {
    return 'Check camera and microphone permissions in Settings.';
  }
  return 'Please try again.';
}

class FvLiveGradient extends StatelessWidget {
  const FvLiveGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .52),
            Colors.transparent,
            Colors.black.withValues(alpha: .86),
          ],
          stops: const [0, .38, 1],
        ),
      ),
    );
  }
}

class FvLiveBadge extends StatelessWidget {
  const FvLiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF315F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class FvLiveBackground extends StatelessWidget {
  const FvLiveBackground({this.icon = Icons.wifi_tethering_rounded, super.key});

  final IconData icon;

  bool get _cameraOff => icon == Icons.videocam_off_rounded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.55, -.35),
          radius: 1.15,
          colors: [Color(0xFF2A103F), Color(0xFF100914), Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _cameraOff ? 48 : 42,
              color: Colors.white.withValues(alpha: _cameraOff ? .32 : .2),
            ),
            if (_cameraOff) ...[
              const SizedBox(height: 12),
              const Text(
                'Camera off',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Your microphone can stay on.',
                style: TextStyle(color: Color(0xFFBEB4C5), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FvLiveStatusCard extends StatelessWidget {
  const FvLiveStatusCard({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 235),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .46),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFEADDFC)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FvRoundLiveButton extends StatelessWidget {
  const FvRoundLiveButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.keyValue,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Key? keyValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          key: keyValue,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(minimumSize: const Size(46, 46)),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

/// Shared live-chat presentation for hosts and viewers.
///
/// Build 18 physical-QA fix: Build 16 rendered only six 11px messages, which
/// looked like a tiny debug feed on an iPhone. Keep more recent activity on
/// screen and use readable mobile text/padding without turning chat into a
/// full-screen panel.
class FvLiveChatList extends StatelessWidget {
  const FvLiveChatList({required this.messages, super.key});

  final List<dynamic> messages;

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;
    return Column(
      key: const Key('fv-live-chat-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible.map((dynamic raw) {
        final user = raw.user as String;
        final text = raw.text as String;
        final level = raw.gifterLevel as int;
        final kind = raw.kind as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .40),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white10),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.28),
                children: [
                  TextSpan(
                    text: '$user ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (level > 1)
                    TextSpan(
                      text: 'L$level ',
                      style: const TextStyle(
                        color: Color(0xFFD8B8FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: kind == 'gift'
                          ? const Color(0xFFFFD596)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
