import 'dart:async';

import 'package:flutter/material.dart';

import 'fameverse_inbox_models.dart';

enum _ChatSafetyAction { block, report }

class FameverseChatScreen extends StatefulWidget {
  const FameverseChatScreen({
    required this.repository,
    required this.userId,
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    super.key,
  });

  final FameverseInboxRepository repository;
  final String userId;
  final String conversationId;
  final String peerId;
  final String peerName;

  @override
  State<FameverseChatScreen> createState() => _FameverseChatScreenState();
}

class _FameverseChatScreenState extends State<FameverseChatScreen> {
  final TextEditingController _composer = TextEditingController();
  List<FvInboxMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _request++;
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await widget.repository.loadMessages(
        widget.userId,
        widget.conversationId,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      try {
        await widget.repository.readConversation(
          widget.userId,
          widget.conversationId,
        );
      } catch (_) {
        // Reading is best effort; message history must remain accessible.
      }
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Messages could not load. Tap Retry.';
      });
    }
  }

  Future<void> _send() async {
    final message = _composer.text.trim();
    if (_sending || message.isEmpty || message.length > 2000) return;
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(
        widget.userId,
        widget.conversationId,
        message,
      );
      if (!mounted) return;
      _composer.clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not sent. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }


  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text(
          'They will not be able to send you messages. '
          'You can still report abusive behavior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await widget.repository.blockUser(widget.userId, widget.peerId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not block this account.')),
        );
      }
    }
  }

  Future<void> _reportUser() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report this user'),
        content: TextField(
          key: const Key('direct-chat-report-reason'),
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Describe the abusive behavior',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || reason == null) return;
    if (reason.length < 5 || reason.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 5 characters.')),
      );
      return;
    }
    try {
      await widget.repository.reportUser(
        widget.userId,
        widget.peerId,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted for review.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('fameverse-direct-chat'),
    backgroundColor: const Color(0xFF0D0912),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0912),
      title: Text(widget.peerName),
      actions: [
        PopupMenuButton<_ChatSafetyAction>(
          key: const Key('direct-chat-safety-menu'),
          tooltip: 'Block or report user',
          onSelected: (action) {
            if (action == _ChatSafetyAction.block) {
              unawaited(_blockUser());
            } else {
              unawaited(_reportUser());
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _ChatSafetyAction.block,
              child: Text('Block user'),
            ),
            PopupMenuItem(
              value: _ChatSafetyAction.report,
              child: Text('Report user'),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Refresh messages',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 70),
                        Center(child: Text(_error!)),
                        Center(
                          child: TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    )
                  : _messages.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 70),
                        Center(child: Text('Say hello to start your chat')),
                      ],
                    )
                  : ListView.builder(
                      key: const Key('direct-chat-history'),
                      padding: const EdgeInsets.all(14),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final mine = message.senderId == widget.userId;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            key: Key('direct-message-${message.id}'),
                            constraints: const BoxConstraints(maxWidth: 285),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF6E34B8)
                                  : const Color(0xFF251C2B),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Text(message.body),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF17101D),
              border: Border(top: BorderSide(color: Color(0xFF3A2745))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('direct-chat-composer'),
                    controller: _composer,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      counterText: '',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('direct-chat-send'),
                  tooltip: 'Send message',
                  onPressed: _sending || _composer.text.trim().isEmpty
                      ? null
                      : _send,
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
