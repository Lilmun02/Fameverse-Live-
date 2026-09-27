import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_beta_backend.dart';
import '../../data/fameverse_creator_backend.dart';
import '../../data/fameverse_economy_backend.dart';
import '../../data/fameverse_live_backend.dart';
import '../profile/coin_exchange_screen.dart';
import '../profile/first_verse_beta_screen.dart';
import '../profile/owner_control_panel.dart';
import 'fameverse_shell_build16.dart';

/// Release shell for the Sep-27 candidate.
///
/// Keeps the battle-tested product shell intact while wiring the release-only
/// entry points that were previously present as files but unreachable in the
/// running app. Owner infrastructure is never rendered for non-owner accounts.
class FameverseReleaseShell extends StatefulWidget {
  const FameverseReleaseShell({
    required this.backend,
    required this.liveBackend,
    required this.identity,
    super.key,
  });

  final FameverseBackend backend;
  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;

  @override
  State<FameverseReleaseShell> createState() => _FameverseReleaseShellState();
}

class _FameverseReleaseShellState extends State<FameverseReleaseShell> {
  late final SupabaseFameverseCreatorBackend _creatorBackend;
  late final SupabaseFameverseEconomyBackend _economyBackend;
  late final SupabaseFameverseBetaBackend _betaBackend;

  String? _role;
  FvCreatorPayoutSummary _payoutSummary = FvCreatorPayoutSummary.empty;
  FvBetaProgramStatus _betaStatus = FvBetaProgramStatus.notEnrolled;

  bool get _isOwner => _role == 'owner';
  bool get _showExchange => _payoutSummary.isVerified;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _creatorBackend = SupabaseFameverseCreatorBackend(client);
    _economyBackend = SupabaseFameverseEconomyBackend(client);
    _betaBackend = SupabaseFameverseBetaBackend(client);
    unawaited(_loadReleaseAccess());
  }

  Future<void> _loadReleaseAccess() async {
    try {
      final results = await Future.wait<dynamic>([
        _creatorBackend.loadRole(widget.identity.id),
        _creatorBackend.loadPayoutSummary(),
        _betaBackend.loadProgramStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _role = results[0] as String?;
        _payoutSummary = results[1] as FvCreatorPayoutSummary;
        _betaStatus = results[2] as FvBetaProgramStatus;
      });
    } catch (_) {
      // Release shortcuts must never block the product shell.
    }
  }

  Future<void> _openOwnerPanel() async {
    if (!_isOwner) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const OwnerControlPanel()),
    );
    await _loadReleaseAccess();
  }

  Future<void> _openFirstVerse() async {
    if (!_betaStatus.enrolled) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FirstVerseBetaScreen(
          backend: _betaBackend,
          economyBackend: _economyBackend,
        ),
      ),
    );
    await _loadReleaseAccess();
  }

  Future<void> _openExchange() async {
    if (!_showExchange) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CoinExchangeScreen(
          creatorBackend: _creatorBackend,
          economyBackend: _economyBackend,
        ),
      ),
    );
    await _loadReleaseAccess();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (_betaStatus.enrolled) {
      actions.add(
        _ReleaseAction(
          key: const Key('release-first-verse-entry'),
          icon: _betaStatus.badgeUnlocked
              ? Icons.auto_awesome_rounded
              : Icons.lock_outline_rounded,
          label: _betaStatus.badgeUnlocked
              ? 'First Verse'
              : 'First Verse ${_betaStatus.completedRequired}/${_betaStatus.requiredTotal}',
          onTap: _openFirstVerse,
        ),
      );
    }

    if (_showExchange) {
      actions.add(
        _ReleaseAction(
          key: const Key('release-coin-exchange-entry'),
          icon: Icons.swap_horiz_rounded,
          label: 'Coin Exchange',
          onTap: _openExchange,
        ),
      );
    }

    if (_isOwner) {
      actions.add(
        _ReleaseAction(
          key: const Key('release-owner-control-entry'),
          icon: Icons.admin_panel_settings_rounded,
          label: 'Owner',
          onTap: _openOwnerPanel,
          ownerOnly: true,
        ),
      );
    }

    return Stack(
      children: [
        FameverseBuild16Shell(
          backend: widget.backend,
          liveBackend: widget.liveBackend,
          identity: widget.identity,
        ),
        if (actions.isNotEmpty)
          Positioned(
            right: 12,
            bottom: 90,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: actions
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: action,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReleaseAction extends StatelessWidget {
  const _ReleaseAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.ownerOnly = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool ownerOnly;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: ownerOnly
                ? const Color(0xF20A0710)
                : const Color(0xE6160D1E),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ownerOnly
                  ? const Color(0xFF644275)
                  : const Color(0xFF75419C),
            ),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFFD5A3FF)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
