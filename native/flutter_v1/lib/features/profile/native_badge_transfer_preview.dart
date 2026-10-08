import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _maxProofBytes = 52428800;

/// Mobile badge claim form. Review and badge assignment are owner-only.
class NativeBadgeTransferPreview extends StatefulWidget {
  const NativeBadgeTransferPreview({super.key});

  @override
  State<NativeBadgeTransferPreview> createState() => _BadgeTransferState();
}

class _BadgeTransferState extends State<NativeBadgeTransferPreview> {
  final _username = TextEditingController();
  final _level = TextEditingController();
  String _platform = 'favorited';
  XFile? _proof;
  Map<String, dynamic>? _claim;
  String? _feedback;
  bool _busy = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _username.dispose();
    _level.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final claim = await _client
          .from('badge_transfer_claims')
          .select('id, status, approved_level, review_note, submitted_at')
          .eq('user_id', uid)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted) setState(() => _claim = claim);
    } catch (_) {
      // The screen must not crash before its backend migration is deployed.
    }
  }

  Future<void> _pickProof() async {
    if (_busy) return;
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final extension = picked.name.split('.').last.toLowerCase();
      if (!const {'mp4', 'mov', 'webm'}.contains(extension) ||
          await picked.length() > _maxProofBytes) {
        setState(() => _feedback = 'Use a screen recording (MP4, MOV, or WebM) under 50 MB.');
        return;
      }
      if (mounted) setState(() { _proof = picked; _feedback = null; });
    } catch (_) {
      if (mounted) setState(() => _feedback = 'Video library could not open.');
    }
  }

  Future<void> _submit() async {
    if (_busy || _claim?['status'] == 'pending' ||
        _claim?['status'] == 'approved') return;
    final uid = _client.auth.currentUser?.id;
    final username = _username.text.trim();
    final badge = int.tryParse(_level.text.trim());
    final proof = _proof;
    if (uid == null || username.length < 2 || username.length > 80 ||
        badge == null || badge < 1 || badge > 99 || proof == null) {
      setState(() => _feedback = 'Enter your source username, badge number, and proof video.');
      return;
    }

    setState(() { _busy = true; _feedback = null; });
    try {
      final ext = proof.name.split('.').last.toLowerCase();
      final mime = ext == 'mov' ? 'video/quicktime' :
          ext == 'webm' ? 'video/webm' : 'video/mp4';
      final objectPath = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await _client.storage.from('badge-transfer-proofs').upload(
        objectPath,
        File(proof.path),
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      await _client.rpc('submit_badge_transfer_claim', params: {
        'p_source_platform': _platform,
        'p_source_username': username,
        'p_source_level': badge,
        'p_evidence_path': objectPath,
      });
      if (!mounted) return;
      setState(() => _feedback = 'Submitted for owner review.');
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() => _feedback = 'Submission unavailable. Please retry when the beta feature is enabled.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _claim?['status']?.toString() ?? '';
    final frozen = status == 'pending' || status == 'approved';
    final info = status == 'approved'
        ? 'Approved at Fameverse badge level ${_claim?['approved_level']}.'
        : status == 'pending'
            ? 'Your proof is pending owner review.'
            : status == 'needs_info'
                ? 'The owner needs more evidence. You may resubmit.'
                : status == 'rejected'
                    ? 'Your previous claim was denied. You may try again.'
                    : '';
    return Container(
      key: const Key('badge-transfer-preview-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17111B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF513862)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bring your badge',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('Transfer your gifter recognition from TikTok, Favorited, or EPIC only. '
              'Show your source username and real badge in a single screen recording.',
              style: TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 8),
          const Text('The Fameverse owner reviews every claim. Only one badge may be '
              'transferred; incorrect proof can be denied or resubmitted.',
              style: TextStyle(fontSize: 11, color: Color(0xFFB8ACBC))),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(info, key: const Key('badge-transfer-status'),
                style: const TextStyle(color: Color(0xFFD5A5FC))),
          ],
          if ((_claim?['review_note']?.toString() ?? '').isNotEmpty)
            Text(_claim!['review_note'].toString(),
                style: const TextStyle(color: Color(0xFFB8ACBC))),
          if (!frozen) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('badge-transfer-source'),
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Source app'),
              items: const [
                DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                DropdownMenuItem(value: 'favorited', child: Text('Favorited')),
                DropdownMenuItem(value: 'epic', child: Text('EPIC')),
              ],
              onChanged: _busy ? null : (value) {
                if (value != null) setState(() => _platform = value);
              },
            ),
            TextField(
              controller: _username,
              key: const Key('badge-transfer-username'),
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Source-app username'),
            ),
            TextField(
              controller: _level,
              key: const Key('badge-transfer-level'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Source badge number (1–99)'),
            ),
            OutlinedButton.icon(
              key: const Key('badge-transfer-choose-video'),
              onPressed: _busy ? null : _pickProof,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(_proof?.name ?? 'Choose screen recording'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('badge-transfer-submit'),
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Submitting…' : 'Submit for owner review'),
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Text(_feedback!, style: const TextStyle(color: Color(0xFFD5A5FC))),
          ],
          const SizedBox(height: 10),
          const Text('Transferred levels are recognition only: they do not '
              'add Fame Coins, gift spending, or unlock spending-based gifts.',
              style: TextStyle(fontSize: 10, color: Color(0xFFB8ACBC))),
        ],
      ),
    );
  }
}
