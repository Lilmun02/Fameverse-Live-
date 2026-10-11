import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Requests manual owner review. Source badge levels never award Fameverse levels.
class BadgeTransferRequestScreen extends StatefulWidget {
  const BadgeTransferRequestScreen({
    required this.userId,
    this.submitRequest,
    super.key,
  });

  final String userId;
  final Future<void> Function(String platform, int level, String proofUrl)?
      submitRequest;

  @override
  State<BadgeTransferRequestScreen> createState() =>
      _BadgeTransferRequestScreenState();
}

class _BadgeTransferRequestScreenState
    extends State<BadgeTransferRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _level = TextEditingController();
  final _proofUrl = TextEditingController();
  String _platform = 'TikTok';
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _level.dispose();
    _proofUrl.dispose();
    super.dispose();
  }

  Future<void> _submitToBackend(
    String platform,
    int level,
    String proofUrl,
  ) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != widget.userId) {
      throw StateError('Badge request account mismatch');
    }
    await client.from('badge_transfer_requests').insert({
      'user_id': widget.userId,
      'source_platform': platform,
      'source_level': level,
      'proof_url': proofUrl,
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final level = int.parse(_level.text.trim());
      final proof = _proofUrl.text.trim();
      await (widget.submitRequest?.call(_platform, level, proof) ??
          _submitToBackend(_platform, level, proof));
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Your request was not submitted. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const Key('badge-transfer-request-screen'),
        appBar: AppBar(title: const Text('Bring Your Badge')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Bring a badge from TikTok, Favorited or Epic.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'An owner must review your proof. Imported badges never grant '
                'Fameverse level points, coins, or unlocked benefits. '
                'Your Fameverse level starts at zero.',
              ),
              const SizedBox(height: 20),
              if (_submitted)
                const ListTile(
                  key: Key('badge-request-pending'),
                  leading: Icon(Icons.hourglass_top_rounded),
                  title: Text('Submitted for owner review'),
                  subtitle: Text('Your request is pending. No level was awarded.'),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        key: const Key('badge-transfer-platform'),
                        initialValue: _platform,
                        decoration: const InputDecoration(
                          labelText: 'Source app',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TikTok', child: Text('TikTok')),
                          DropdownMenuItem(
                            value: 'Favorited',
                            child: Text('Favorited'),
                          ),
                          DropdownMenuItem(value: 'Epic', child: Text('Epic')),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() {
                                  _platform = value ?? _platform;
                                }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('badge-transfer-level'),
                        controller: _level,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Badge number on source app',
                        ),
                        validator: (value) {
                          final level = int.tryParse(value?.trim() ?? '');
                          if (level == null || level < 1 || level > 100) {
                            return 'Enter a badge number from 1 to 100.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('badge-transfer-proof'),
                        controller: _proofUrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Link to badge proof',
                          helperText: 'Public profile or image evidence link',
                        ),
                        validator: (value) {
                          final proof = value?.trim() ?? '';
                          final uri = Uri.tryParse(proof);
                          if (proof.length > 2048 ||
                              uri == null ||
                              uri.scheme != 'https' ||
                              uri.host.isEmpty) {
                            return 'Enter a valid HTTPS proof link.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _error!,
                            key: const Key('badge-transfer-error'),
                          ),
                        ),
                      const SizedBox(height: 18),
                      FilledButton(
                        key: const Key('badge-transfer-submit'),
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'Submitting…' : 'Request owner review',
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
