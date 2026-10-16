import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fameverse_chat_screen.dart';
import 'fameverse_compose_message_screen.dart';
import 'fameverse_inbox_models.dart';
import 'fameverse_inbox_repository.dart';

class FameverseInboxScreen extends StatefulWidget {
  const FameverseInboxScreen({
    required this.userId,
    this.repository,
    super.key,
  });

  final String userId;
  final FameverseInboxRepository? repository;

  @override
  State<FameverseInboxScreen> createState() => _FameverseInboxScreenState();
}

class _FameverseInboxScreenState extends State<FameverseInboxScreen> {
  late final FameverseInboxRepository _repo =
      widget.repository ??
      SupabaseFameverseInboxRepository(Supabase.instance.client);
  FvInboxSnapshot _snapshot = const FvInboxSnapshot(
    conversations: [],
    activities: [],
  );
  bool _loading = true;
  String? _error;
  int _tab = 0;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant FameverseInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _snapshot = const FvInboxSnapshot(conversations: [], activities: []);
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final request = ++_request;
    final userId = widget.userId;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await _repo.load(userId);
      if (!mounted || request != _request || userId != widget.userId) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request || userId != widget.userId) return;
      setState(() {
        _loading = false;
        _error = 'Inbox is unavailable. Pull down or tap Retry.';
      });
    }
  }

  Future<void> _openConversation(FvInboxConversation conversation) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameverseChatScreen(
          repository: _repo,
          userId: widget.userId,
          conversationId: conversation.id,
          peerName: conversation.peerName,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _compose() async {
    final conversation = await Navigator.of(context).push<FvInboxConversation>(
      MaterialPageRoute(
        builder: (context) => FameverseComposeMessageScreen(
          userId: widget.userId,
          repository: _repo,
        ),
      ),
    );
    if (!mounted || conversation == null) return;
    await _openConversation(conversation);
  }

  Future<void> _openActivity(FvInboxActivity activity) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: Text(activity.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted || !activity.unread) return;
    try {
      await _repo.readActivity(widget.userId, activity.id);
      if (mounted) await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not mark activity as read.')),
        );
      }
    }
  }

  int get _messageUnread => _snapshot.conversations.fold(
    0,
    (count, item) => count + item.unreadCount,
  );
  int get _activityUnread =>
      _snapshot.activities.where((activity) => activity.unread).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('fameverse-inbox-screen'),
    backgroundColor: const Color(0xFF0D0912),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0912),
      title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          key: const Key('inbox-compose-button'),
          tooltip: 'New message',
          onPressed: _compose,
          icon: const Icon(Icons.edit_square),
        ),
        IconButton(
          tooltip: 'Refresh inbox',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your conversations and activity',
                style: TextStyle(color: Color(0xFFC0A7CD), fontSize: 13),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _InboxTab(
                    key: const Key('inbox-messages-tab'),
                    label: 'Messages',
                    count: _messageUnread,
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InboxTab(
                    key: const Key('inbox-activity-tab'),
                    label: 'Activity',
                    count: _activityUnread,
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                key: const Key('inbox-content'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                children: [
                  if (_error != null) ...[
                    Card(
                      key: const Key('inbox-load-error'),
                      color: const Color(0xFF321A35),
                      child: ListTile(
                        leading: const Icon(Icons.wifi_off_rounded),
                        title: Text(_error!),
                        trailing: TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_loading && _error == null && _tab == 0) ...[
                    if (_snapshot.conversations.isEmpty)
                      const _InboxEmpty(
                        key: Key('inbox-messages-empty'),
                        icon: Icons.forum_outlined,
                        title: 'No messages yet',
                        description:
                            'Tap the compose button to message a creator.',
                      )
                    else
                      for (final conversation in _snapshot.conversations)
                        Card(
                          key: Key('inbox-chat-${conversation.id}'),
                          color: const Color(0xFF201627),
                          child: ListTile(
                            onTap: () => _openConversation(conversation),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6E34B8),
                              child: Icon(Icons.person_rounded),
                            ),
                            title: Text(
                              conversation.peerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              conversation.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: conversation.unreadCount > 0
                                ? CircleAvatar(
                                    radius: 13,
                                    backgroundColor: const Color(0xFFAF57E4),
                                    child: Text(
                                      '${conversation.unreadCount}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                  ],
                  if (!_loading && _error == null && _tab == 1) ...[
                    if (_snapshot.activities.isEmpty)
                      const _InboxEmpty(
                        key: Key('inbox-activity-empty'),
                        icon: Icons.notifications_none_rounded,
                        title: 'No activity yet',
                        description:
                            'Account updates and notifications appear here.',
                      )
                    else
                      for (final activity in _snapshot.activities)
                        Card(
                          key: Key('inbox-activity-${activity.id}'),
                          color: activity.unread
                              ? const Color(0xFF352042)
                              : const Color(0xFF201627),
                          child: ListTile(
                            onTap: () => _openActivity(activity),
                            leading: Icon(
                              activity.unread
                                  ? Icons.markunread_rounded
                                  : Icons.mark_email_read_outlined,
                              color: const Color(0xFFD6A2FF),
                            ),
                            title: Text(
                              activity.title,
                              style: TextStyle(
                                fontWeight: activity.unread
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              activity.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected
          ? const Color(0xFF6E34B8)
          : const Color(0xFF241B2D),
      side: const BorderSide(color: Color(0xFF654776)),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (count > 0) ...[const SizedBox(width: 8), Text('($count)')],
      ],
    ),
  );
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 22),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFFC78AFF), size: 42),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB7A7C1)),
        ),
      ],
    ),
  );
}
