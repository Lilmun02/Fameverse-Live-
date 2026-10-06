part of 'native_camera_screen.dart';

class _NativeLiveSummaryScreen extends StatelessWidget {
  const _NativeLiveSummaryScreen({required this.live});

  final FvCreatorLiveSummary live;

  String get _duration {
    final started = live.startedAt;
    final ended = live.endedAt;
    if (started == null || ended == null || ended.isBefore(started)) return '—';
    final elapsed = ended.difference(started);
    if (elapsed.inHours >= 1) {
      return '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';
    }
    return '${elapsed.inMinutes}m ${elapsed.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0911),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
          children: [
            const Text(
              'LIVE ENDED',
              style: TextStyle(
                color: Color(0xFFFF4D77),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Session summary',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              live.title,
              style: const TextStyle(color: Color(0xFFC4B9CC), fontSize: 15),
            ),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _SummaryStat(label: 'Duration', value: _duration),
                _SummaryStat(label: 'FameTaps', value: '${live.rawTaps}'),
                _SummaryStat(label: 'Gifts', value: '${live.giftCount}'),
                _SummaryStat(label: 'Gift coins', value: '${live.giftCoins}'),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF17101F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creator earnings',
                    style: TextStyle(
                      color: Color(0xFFB9ACC2),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '—',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Cash earnings are not calculated in beta because Fameverse payout conversion is not configured yet.',
                    style: TextStyle(color: Color(0xFF9E93A6), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFFC8A8F7),
                foregroundColor: const Color(0xFF2A163B),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF21172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA99EB0), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
