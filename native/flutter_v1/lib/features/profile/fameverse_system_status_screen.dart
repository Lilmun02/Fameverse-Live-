import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/backend_runtime.dart';
import '../../data/startup_update_service.dart';

class FameverseSystemStatusScreen extends StatefulWidget {
  const FameverseSystemStatusScreen({super.key, this.initialSection = 'algo'});

  final String initialSection;

  @override
  State<FameverseSystemStatusScreen> createState() =>
      _FameverseSystemStatusScreenState();
}

class _FameverseSystemStatusScreenState
    extends State<FameverseSystemStatusScreen> {
  static const _releaseChannel = String.fromEnvironment(
    'FAMEVERSE_RELEASE_CHANNEL',
    defaultValue: 'internal',
  );

  final ScrollController _scroll = ScrollController();
  final GlobalKey _algoKey = GlobalKey();
  final GlobalKey _updatesKey = GlobalKey();

  bool _checking = false;
  String? _lastCheckMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpToInitialSection(),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToInitialSection() {
    final key = widget.initialSection == 'updates' ? _updatesKey : _algoKey;
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: .08,
    );
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _lastCheckMessage = null;
    });
    try {
      final result = await FvStartupUpdateService(
        Supabase.instance.client,
      ).sync(channel: _releaseChannel);
      if (!mounted) return;
      setState(() {
        _lastCheckMessage = result.backendChanged
            ? 'Backend revision ${result.backendRevision} synced.'
            : 'Fameverse backend is up to date.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastCheckMessage =
            'Could not reach the backend updater. Cached settings remain active.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manifest = FvBackendRuntime.manifest;
    final algoEnabled = manifest.featureEnabled('fame_algo_v1');
    final updaterEnabled = manifest.featureEnabled('backend_updater');
    final revision = FvBackendRuntime.backendRevision;
    final label = FvBackendRuntime.releaseLabel;

    return Scaffold(
      key: const Key('fameverse-system-status-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Fameverse system',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A1537), Color(0xFF100B14)],
                ),
                border: Border.all(color: const Color(0xFF513160)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hub_rounded, color: Color(0xFFC985FF), size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fameverse intelligence & updates',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'See what powers discovery and verify the backend revision this app is using.',
                          style: TextStyle(
                            color: Color(0xFFB5A8BC),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Container(
              key: _algoKey,
              padding: const EdgeInsets.all(18),
              decoration: _panel(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _FameTapMark(),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FAME ALGO V1',
                              key: Key('settings-fame-algo-title'),
                              style: TextStyle(
                                color: Color(0xFFD9A5FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Fameverse discovery engine',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(
                        text: algoEnabled ? 'ACTIVE' : 'OFF',
                        active: algoEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fame Algo ranks discovery using Fameverse signals such as follows, mutual connections, eligible FameTaps, gifts, active Stories, active Lives, freshness, momentum and creator-discovery boosts.',
                    style: TextStyle(color: Color(0xFFB7AABD), height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Paid activity is capped so gifts alone cannot buy the top of the feed. The For You lane should preserve the server order rather than replacing it with a local client score.',
                    style: TextStyle(
                      color: Color(0xFF9E92A4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              key: _updatesKey,
              padding: const EdgeInsets.all(18),
              decoration: _panel(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.system_update_alt_rounded,
                        color: Color(0xFFC985FF),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'App & backend updates',
                          key: Key('settings-backend-updater-title'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _StatusChip(
                        text: updaterEnabled ? 'ACTIVE' : 'OFF',
                        active: updaterEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Channel', value: _releaseChannel),
                  _InfoRow(label: 'Backend revision', value: '$revision'),
                  _InfoRow(label: 'Release label', value: label),
                  const SizedBox(height: 8),
                  const Text(
                    'The updater can sync supported backend configuration and notices. It cannot add a screen or native capability that was never compiled into the installed app.',
                    style: TextStyle(
                      color: Color(0xFF9E92A4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (_lastCheckMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _lastCheckMessage!,
                      key: const Key('backend-update-last-check'),
                      style: const TextStyle(
                        color: Color(0xFFD6C9DD),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('backend-update-check-now'),
                      onPressed: _checking ? null : _checkNow,
                      icon: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(_checking ? 'Checking…' : 'Check now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9E92A4), fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B2050) : const Color(0xFF2A202D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF9658C9) : const Color(0xFF55475A),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFFDCAEFF) : const Color(0xFFB6A9BA),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _FameTapMark extends StatelessWidget {
  const _FameTapMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 34,
            color: Color(0xFF9B55FF),
          ),
          Positioned(
            bottom: 7,
            child: Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panel() {
  return BoxDecoration(
    color: const Color(0xFF151018),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFF37283F)),
  );
}
