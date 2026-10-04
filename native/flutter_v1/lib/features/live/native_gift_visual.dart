import 'package:flutter/material.dart';

import '../../data/fameverse_live_backend.dart';

/// Stable gift-store poster art.
///
/// Cinematic gifts use deterministic poster art in the tray; the remote video
/// plays only after a successful send.
class NativeGiftTrayVisual extends StatelessWidget {
  const NativeGiftTrayVisual({required this.gift, this.size = 54, super.key});

  final FvGiftDefinition gift;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (gift.cinematic) {
      return SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A2564), Color(0xFF24142F), Color(0xFF17101F)],
            ),
            border: Border.all(color: const Color(0x335F37A1)),
          ),
          child: Center(
            child: Text(gift.symbol, style: TextStyle(fontSize: size * .46)),
          ),
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(gift.symbol, style: TextStyle(fontSize: size * .52)),
      ),
    );
  }
}
