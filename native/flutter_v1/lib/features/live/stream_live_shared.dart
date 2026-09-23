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
            Colors.black.withValues(alpha: .66),
            Colors.transparent,
            Colors.black.withValues(alpha: .9),
          ],
          stops: const [0, .42, 1],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF315F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class FvLiveBackground extends StatelessWidget {
  const FvLiveBackground({this.icon = Icons.wifi_tethering_rounded, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.6, -.4),
          radius: 1.2,
          colors: [Color(0xFF351453), Color(0xFF100914), Colors.black],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 76, color: Colors.white.withValues(alpha: .18)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .64),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
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
          style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class FvLiveChatList extends StatelessWidget {
  const FvLiveChatList({required this.messages, super.key});

  final List<dynamic> messages;

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 7
        ? messages.sublist(messages.length - 7)
        : messages;
    return Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.25),
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
