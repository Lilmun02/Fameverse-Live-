import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FvInboxItem {
  const FvInboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;

  factory FvInboxItem.fromMap(Map<String, dynamic> row) => FvInboxItem(
    id: row['id']?.toString() ?? '',
    title: row['title']?.toString() ?? '',
    body: row['body']?.toString() ?? '',
    createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
  );
}

/// Personal, read-only inbox. The service must enforce user_id = auth.uid()
/// through RLS; no client may forge a notification for another account.
class FameverseInboxScreen extends StatefulWidget {
  const FameverseInboxScreen({required this.userId, this.loadItems, super.key});

  final String userId;
  final Future<List<FvInboxItem>> Function(String userId)? loadItems;

  @override
  State<FameverseInboxScreen> createState() => _FameverseInboxScreenState();
}

class _FameverseInboxScreenState extends State<FameverseInboxScreen> {
  List<FvInboxItem> _items = const [];
  bool _loading = true;
  String? _error;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant FameverseInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.loadItems != widget.loadItems) {
      _items = const [];
      _refresh();
    }
  }

  Future<List<FvInboxItem>> _fromBackend(String userId) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Inbox account does not match the signed-in account');
    }
    final response = await client
        .from('user_inbox_items')
        .select('id, title, body, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return response.map((row) => FvInboxItem.fromMap(row)).toList();
  }

  Future<void> _refresh() async {
    final request = ++_requestVersion;
    final userId = widget.userId;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items =
          await (widget.loadItems?.call(userId) ?? _fromBackend(userId));
      if (!mounted || request != _requestVersion || widget.userId != userId) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestVersion || widget.userId != userId) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Inbox could not load. Pull to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('fameverse-inbox-screen'),
    appBar: AppBar(title: const Text('Inbox')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ListTile(
              key: const Key('inbox-load-error'),
              leading: const Icon(Icons.error_outline),
              title: Text(_error!),
            )
          else if (_items.isEmpty)
            const ListTile(
              key: Key('inbox-empty'),
              leading: Icon(Icons.mark_email_read_outlined),
              title: Text('Your inbox is empty'),
              subtitle: Text('Account updates will appear here.'),
            )
          else
            for (final item in _items)
              Card(
                key: Key('inbox-item-${item.id}'),
                child: ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                  isThreeLine: item.body.isNotEmpty,
                ),
              ),
        ],
      ),
    ),
  );
}
