import 'package:flutter/material.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

/// A later-release iOS-only navigation chrome candidate.
/// iOS 26+ uses Apple's real UIKit Liquid Glass; iOS 27 inherits system
/// transparency settings. Original Material NavigationBar is preserved
/// for Android, web and native Live camera setup.
class FameverseIos27GlassNav extends StatelessWidget {
  const FameverseIos27GlassNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const destinations = <LiquidGlassBarItem>[
    LiquidGlassBarItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      sfSymbol: 'house',
      selectedSfSymbol: 'house.fill',
      label: 'Home',
    ),
    LiquidGlassBarItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      sfSymbol: 'safari',
      selectedSfSymbol: 'safari.fill',
      label: 'Discover',
    ),
    LiquidGlassBarItem(
      icon: Icons.videocam_outlined,
      selectedIcon: Icons.videocam_rounded,
      sfSymbol: 'video',
      selectedSfSymbol: 'video.fill',
      label: 'Live',
    ),
    LiquidGlassBarItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      sfSymbol: 'person.crop.circle',
      selectedSfSymbol: 'person.crop.circle.fill',
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: LiquidGlassBottomBar(
          currentIndex: selectedIndex,
          items: destinations,
          onTap: onDestinationSelected,
          // Keep Apple's material native; only tint selection.
          tint: const Color(0xFFC982FF),
          height: 76,
          showLabels: true,
        ),
      ),
    );
  }
}
