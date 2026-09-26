import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';

class FameverseEditProfileScreen extends StatefulWidget {
  const FameverseEditProfileScreen({
    required this.profile,
    required this.avatarBusy,
    required this.onChangePhoto,
    required this.onSave,
    super.key,
  });

  final FvProfile profile;
  final bool avatarBusy;
  final VoidCallback onChangePhoto;
  final Future<void> Function({
    required String displayName,
    required String username,
    required String bio,
  })
  onSave;

  @override
  State<FameverseEditProfileScreen> createState() =>
      _FameverseEditProfileScreenState();
}

class _FameverseEditProfileScreenState
    extends State<FameverseEditProfileScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _username = TextEditingController(text: widget.profile.username ?? '');
    final currentBio = widget.profile.bio.trim();
    _bio = TextEditingController(
      text: currentBio.toLowerCase() == 'admin - owner' ? '' : currentBio,
    );
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSave(
        displayName: _displayName.text,
        username: _username.text,
        bio: _bio.text,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('fameverse-fullscreen-edit-profile'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Edit profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            key: const Key('save-profile-top-action'),
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB45FFF),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x77551782), blurRadius: 24),
                      ],
                    ),
                    child: ClipOval(
                      child: _ProfileAvatar(profile: widget.profile),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: IconButton.filled(
                      key: const Key('edit-profile-change-photo'),
                      onPressed: widget.avatarBusy
                          ? null
                          : widget.onChangePhoto,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF8F43E0),
                        foregroundColor: Colors.white,
                      ),
                      icon: widget.avatarBusy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 19),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.avatarBusy ? null : widget.onChangePhoto,
              child: const Text(
                'Change profile photo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 18),
            const _EditSectionLabel('PROFILE INFO'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151417),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF2C242F)),
              ),
              child: Column(
                children: [
                  _EditField(
                    keyValue: const Key('edit-display-name'),
                    label: 'Name',
                    helper: 'The name people see across Fameverse',
                    controller: _displayName,
                    maxLength: 40,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _EditField(
                    keyValue: const Key('edit-username'),
                    label: 'Username',
                    helper: 'Your unique @handle',
                    controller: _username,
                    maxLength: 24,
                    prefixText: '@',
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _EditField(
                    keyValue: const Key('edit-bio'),
                    label: 'Bio',
                    helper: 'Tell people who you are',
                    controller: _bio,
                    maxLength: 160,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF24132F), Color(0xFF130E17)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4B3157)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.public_rounded,
                    color: Color(0xFFC782FF),
                    size: 21,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Your name, username, bio and profile photo are public identity details. Internal owner/admin labels never belong on the public profile.',
                      style: TextStyle(
                        color: Color(0xFFB8ACBC),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save-profile-button'),
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF8C46DF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSectionLabel extends StatelessWidget {
  const _EditSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8F8196),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.15,
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.keyValue,
    required this.label,
    required this.helper,
    required this.controller,
    required this.maxLength,
    this.maxLines = 1,
    this.prefixText,
  });

  final Key keyValue;
  final String label;
  final String helper;
  final TextEditingController controller;
  final int maxLength;
  final int maxLines;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: const TextStyle(color: Color(0xFF8E858F), fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            key: keyValue,
            controller: controller,
            maxLength: maxLength,
            minLines: maxLines > 1 ? 3 : 1,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixText: prefixText,
              counterStyle: const TextStyle(
                color: Color(0xFF756E77),
                fontSize: 10,
              ),
              filled: true,
              fillColor: const Color(0xFF0F0B12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF312737)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF312737)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF9D55F0),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl?.trim();
    if (avatar != null && avatar.isNotEmpty) {
      return Image.network(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFallback(profile: profile),
      );
    }
    return _AvatarFallback(profile: profile);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.profile});

  final FvProfile profile;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF352044),
      child: Center(
        child: Text(
          profile.initial,
          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
