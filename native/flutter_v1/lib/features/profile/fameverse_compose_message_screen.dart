import 'package:flutter/material.dart';

import 'fameverse_inbox_models.dart';

/// Search existing Fameverse accounts and start an RLS-protected conversation.
class FameverseComposeMessageScreen extends StatefulWidget {
  const FameverseComposeMessageScreen({
    required this.userId,
    required this.repository,
    super.key,
  });

  final String userId;
  final FameverseInboxRepository repository;

  @override
  State<FameverseComposeMessageScreen> createState() =>
      _FameverseComposeMessageScreenState();
}

class _FameverseComposeMessageScreenState
    extends State<FameverseComposeMessageScreen> {
  final TextEditingController _search = TextEditingController();
  List<FvInboxContact> _results = const [];
  String? _error;
  bool _searching = false;
  bool _starting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_searching) return;
    final value = _search.text.trim();
    if (value.length < 2) {
      setState(() {
        _results = const [];
        _error = 'Enter at least two characters of a username.';
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final users = await widget.repository.searchContacts(
        widget.userId,
        value,
      );
      if (!mounted) return;
      setState(() => _results = users);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Creator search unavailable. Try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _start(FvInboxContact peer) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final id = await widget.repository.startConversation(
        widget.userId,
        peer.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        FvInboxConversation(
          id: id,
          peerId: peer.id,
          peerName: peer.displayName,
          peerHandle: peer.username,
          preview: '',
          unreadCount: 0,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not start the chat. Try again.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('fameverse-compose-message'),
    backgroundColor: const Color(0xFF0D0912),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0912),
      title: const Text('New message'),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('inbox-search-creator'),
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search a Fameverse username',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Find creator',
                  onPressed: _find,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _find(),
            ),
            if (_searching)
              const LinearProgressIndicator()
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_error!),
              ),
            const SizedBox(height: 14),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Search for a creator to start a private chat.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final peer = _results[index];
                        return ListTile(
                          key: Key('inbox-contact-${peer.id}'),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline_rounded),
                          ),
                          title: Text(peer.displayName),
                          subtitle: Text('@${peer.username}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _starting ? null : () => _start(peer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
