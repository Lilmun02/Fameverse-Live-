import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../profile/fameverse_public_profile_screen.dart';

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

/// Light edge treatment only. The camera should remain crisp and dominant;
/// Fameverse chrome must not make the Live picture look muddy or low quality.
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
            Colors.black.withValues(alpha: .22),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: .48),
          ],
          stops: const [0, .20, .68, 1],
        ),
      ),
    );
  }
}

/// FameTaps are a Fameverse product signal, not a generic fire emoji.
/// The purple F + flame mark is the canonical compact Live representation.
class FvFameTapMark extends StatelessWidget {
  const FvFameTapMark({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('fame-tap-mark'),
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: size,
            color: const Color(0xFF9B55FF),
            shadows: const [
              Shadow(color: Color(0xAA7A2DDB), blurRadius: 7),
            ],
          ),
          Positioned(
            bottom: size * .16,
            child: Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * .43,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
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
        color: const Color(0xFF6E2CCB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB86BFF), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x668E4DFF), blurRadius: 9)],
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

class FvLiveCommentComposer extends StatelessWidget {
  const FvLiveCommentComposer({
    required this.controller,
    required this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('live-multiline-comment-composer'),
      controller: controller,
      maxLength: 160,
      minLines: 1,
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: const TextStyle(fontSize: 15, height: 1.22),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: const Color(0xD9110B15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF4B365B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF4B365B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF9B55FF), width: 1.4),
        ),
      ),
    );
  }
}

/// This is the Live controls button. The FameTaps identity is intentionally not
/// reused here so users do not confuse a control menu with the product metric.
class FvFameActionButton extends StatelessWidget {
  const FvFameActionButton({
    required this.onPressed,
    this.keyValue,
    this.tooltip = 'Live actions',
    super.key,
  });

  final VoidCallback? onPressed;
  final Key? keyValue;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xE617111D),
        border: Border.all(color: const Color(0xFF7F4A99), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x442F133E), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: IconButton(
        key: keyValue,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: Color(0xFFE5D8EB),
          size: 25,
        ),
      ),
    );
  }
}

class FvLiveChatList extends StatelessWidget {
  const FvLiveChatList({required this.messages, super.key});

  final List<dynamic> messages;

  Future<void> _openProfile(
    BuildContext context,
    String userId,
    String fallbackName,
  ) async {
    try {
      final viewerId = Supabase.instance.client.auth.currentUser?.id;
      if (viewerId == null || !context.mounted) return;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id,username,display_name,bio,avatar_url,created_at')
          .eq('id', userId)
          .maybeSingle();
      if (row == null || !context.mounted) return;
      final profile = FvProfile(
        id: row['id']?.toString() ?? userId,
        username: row['username']?.toString(),
        displayName: row['display_name']?.toString() ?? fallbackName,
        bio: row['bio']?.toString() ?? '',
        avatarUrl: row['avatar_url']?.toString(),
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => FameversePublicProfileScreen(
            viewerUserId: viewerId,
            targetUserId: userId,
            initialProfile: profile,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Profile could not open.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 7
        ? messages.sublist(messages.length - 7)
        : messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible.map((dynamic raw) {
        final user = (raw.user as String).trim();
        final userId = raw.userId?.toString();
        final text = (raw.text as String).trim();
        final level = raw.gifterLevel as int;
        final kind = raw.kind as String;
        final initial = user.isEmpty
            ? 'F'
            : user.characters.first.toUpperCase();
        final isGift = kind == 'gift';
        final canOpenProfile = userId != null && userId.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canOpenProfile
                  ? () => _openProfile(
                      context,
                      userId,
                      user.isEmpty ? 'Fameverse User' : user,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                key: isGift ? const Key('v2-highlighted-gift-chat') : null,
                padding: isGift
                    ? const EdgeInsets.fromLTRB(7, 6, 9, 6)
                    : const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: isGift
                    ? BoxDecoration(
                        color: const Color(0xD91A0E24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFB34EFF),
                          width: 1,
                        ),
                      )
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8E4DFF), Color(0xFF3C1A5A)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFB478FF),
                          width: .8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.isEmpty ? 'Fameverse viewer' : user,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (level > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6E32B9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Lv. $level',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            text,
                            style: TextStyle(
                              color: isGift
                                  ? const Color(0xFFFFD8FF)
                                  : const Color(0xFFF5EFF8),
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: isGift
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
