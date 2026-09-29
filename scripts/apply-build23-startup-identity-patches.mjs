import { readFile, writeFile } from 'node:fs/promises'

const root = new URL('../', import.meta.url)

async function read(path) {
  return readFile(new URL(path, root), 'utf8')
}

async function write(path, content) {
  await writeFile(new URL(path, root), content, 'utf8')
}

function replaceExact(content, before, after, label) {
  const first = content.indexOf(before)
  if (first === -1) {
    throw new Error(`[build23-final-patch] ${label}: expected source block was not found`)
  }
  if (content.indexOf(before, first + before.length) !== -1) {
    throw new Error(`[build23-final-patch] ${label}: expected source block was not unique`)
  }
  return content.slice(0, first) + after + content.slice(first + before.length)
}

let changed = false

// PATCH A — Start the minimum splash timer only after Flutter's first frame is
// actually rendered. This prevents native iOS launch time from consuming the
// splash duration before the user can see it.
{
  const path = 'native/flutter_v1/lib/app/fameverse_app.dart'
  let source = await read(path)

  if (!source.includes('Duration(milliseconds: 1500)')) {
    source = replaceExact(
      source,
      `    _splashTimer = Timer(const Duration(milliseconds: 1050), () {\n      if (mounted) setState(() => _splashComplete = true);\n    });`,
      `    WidgetsBinding.instance.addPostFrameCallback((_) {\n      if (!mounted || _splashTimer != null) return;\n      _splashTimer = Timer(const Duration(milliseconds: 1500), () {\n        if (mounted) setState(() => _splashComplete = true);\n      });\n    });`,
      'splash visible-duration timer',
    )
    changed = true
  }

  if (!source.includes('width: 94,\n      height: 94,')) {
    source = replaceExact(
      source,
      `      width: 116,\n      height: 116,`,
      `      width: 94,\n      height: 94,`,
      'compact splash mark size',
    )
    source = replaceExact(
      source,
      `            top: 19,\n            child: Icon(\n              Icons.workspace_premium_rounded,\n              size: 42,`,
      `            top: 13,\n            child: Icon(\n              Icons.workspace_premium_rounded,\n              size: 32,`,
      'compact splash crown',
    )
    source = replaceExact(
      source,
      `            bottom: 18,\n            child: Text(\n              'F',\n              style: TextStyle(\n                fontSize: 48,`,
      `            bottom: 13,\n            child: Text(\n              'F',\n              style: TextStyle(\n                fontSize: 38,`,
      'compact splash F mark',
    )
    source = replaceExact(
      source,
      `                      const _FameverseMark(),\n                      const SizedBox(height: 22),\n                      const Text(\n                        'FAMEVERSE',\n                        style: TextStyle(\n                          fontSize: 29,`,
      `                      const _FameverseMark(),\n                      const SizedBox(height: 16),\n                      const Text(\n                        'FAMEVERSE',\n                        style: TextStyle(\n                          fontSize: 26,`,
      'compact splash title',
    )
    source = replaceExact(
      source,
      `                      const SizedBox(height: 42),\n                      SizedBox(\n                        width: 112,`,
      `                      const SizedBox(height: 30),\n                      SizedBox(\n                        width: 92,`,
      'compact splash progress',
    )
    changed = true
  }

  await write(path, source)
}

// PATCH B — Profile and account role must come from one authoritative backend
// response tied to auth.uid(). A stale profile can never be paired with a newer
// owner/admin role (or vice versa).
{
  const path = 'native/flutter_v1/lib/features/shell/fameverse_shell_build23.dart'
  let source = await read(path)

  if (!source.includes('Future<({FvProfile profile, String? role})?> _loadAuthoritativeAccount()')) {
    source = replaceExact(
      source,
      `  Future<void> _refreshRole() async {`,
      `  Future<({FvProfile profile, String? role})?> _loadAuthoritativeAccount() async {\n    final expectedId = widget.identity.id;\n    try {\n      final raw = await Supabase.instance.client.rpc('get_my_fameverse_identity');\n      Map<String, dynamic>? row;\n      if (raw is List && raw.isNotEmpty && raw.first is Map) {\n        row = Map<String, dynamic>.from(raw.first as Map);\n      } else if (raw is Map) {\n        row = Map<String, dynamic>.from(raw);\n      }\n      if (row == null) return null;\n\n      final userId = (row['user_id'] as String?)?.trim() ?? '';\n      if (userId != expectedId) {\n        throw StateError('current-account-mismatch');\n      }\n      final username = (row['username'] as String?)?.trim();\n      final displayName = (row['display_name'] as String?)?.trim();\n      final role = (row['role'] as String?)?.trim().toLowerCase();\n      final profile = FvProfile(\n        id: userId,\n        displayName: displayName == null || displayName.isEmpty\n            ? (username?.isNotEmpty == true ? username! : 'Fameverse User')\n            : displayName,\n        username: username == null || username.isEmpty ? null : username,\n        bio: (row['bio'] as String?) ?? '',\n        avatarUrl: row['avatar_url'] as String?,\n        createdAt: null,\n      );\n      return (profile: profile, role: role);\n    } catch (_) {\n      final liveIdentity = widget.backend.currentIdentity;\n      if (liveIdentity == null || liveIdentity.id != expectedId) return null;\n      final results = await Future.wait<dynamic>([\n        widget.backend.loadProfile(expectedId),\n        widget.backend.loadAccountRole(expectedId),\n      ]);\n      final profile = results[0] as FvProfile?;\n      if (profile == null) return null;\n      final role = (results[1] as String?)?.trim().toLowerCase();\n      return (profile: profile, role: role);\n    }\n  }\n\n  Future<void> _refreshRole() async {`,
      'authoritative account loader insertion',
    )
    changed = true
  }

  if (!source.includes('final account = await _loadAuthoritativeAccount();\n      if (!mounted || account == null) return;\n      setState(() {\n        _profile = account.profile;\n        _accountRole = account.role;')) {
    source = replaceExact(
      source,
      `  Future<void> _refreshRole() async {\n    try {\n      final role = await widget.backend.loadAccountRole(widget.identity.id);\n      if (mounted) setState(() => _accountRole = role);\n    } catch (_) {\n      // Role decoration must never block the public product shell.\n    }\n  }`,
      `  Future<void> _refreshRole() async {\n    try {\n      final account = await _loadAuthoritativeAccount();\n      if (!mounted || account == null) return;\n      setState(() {\n        _profile = account.profile;\n        _accountRole = account.role;\n      });\n    } catch (_) {\n      // Role decoration must never block the public product shell.\n    }\n  }`,
      'authoritative role refresh',
    )
    changed = true
  }

  if (source.includes('        widget.backend.loadProfile(widget.identity.id),')) {
    source = replaceExact(
      source,
      `        widget.backend.loadProfile(widget.identity.id),`,
      `        _loadAuthoritativeAccount(),`,
      'authoritative profile refresh source',
    )
    source = replaceExact(
      source,
      `      if (!mounted) return;\n      setState(() {\n        _profile = results[0] as FvProfile?;\n        _network = results[1] as FvFollowNetwork;`,
      `      if (!mounted) return;\n      final account = results[0] as ({FvProfile profile, String? role})?;\n      if (account == null || account.profile.id != widget.identity.id) {\n        throw StateError('current-account-mismatch');\n      }\n      setState(() {\n        _profile = account.profile;\n        _accountRole = account.role;\n        _network = results[1] as FvFollowNetwork;`,
      'atomic profile and role state refresh',
    )
    changed = true
  }

  if (source.includes('  void _openCreatorStudio(FvProfile profile) {')) {
    source = replaceExact(
      source,
      `  void _openCreatorStudio(FvProfile profile) {\n    if (!_ensureSupplementalBackends()) {\n      _message('Creator Studio is reconnecting.');\n      return;\n    }\n    if (_isOwner) {\n      Navigator.of(context).push<void>(\n        MaterialPageRoute(\n          builder: (context) => Build23OwnerControlCenterScreen(\n            onOpenCreatorStudio: () => _openPersonalCreatorStudio(profile),\n          ),\n        ),\n      );\n      return;\n    }\n    _openPersonalCreatorStudio(profile);\n  }`,
      `  Future<void> _openCreatorStudio(FvProfile profile) async {\n    if (!_ensureSupplementalBackends()) {\n      _message('Creator Studio is reconnecting.');\n      return;\n    }\n\n    final account = await _loadAuthoritativeAccount();\n    if (!mounted) return;\n    if (account == null || account.profile.id != widget.identity.id) {\n      _message('Your account session changed. Refreshing Fameverse.');\n      await _refreshAll();\n      return;\n    }\n\n    setState(() {\n      _profile = account.profile;\n      _accountRole = account.role;\n    });\n    final currentProfile = account.profile;\n\n    if (account.role == 'owner') {\n      Navigator.of(context).push<void>(\n        MaterialPageRoute(\n          builder: (context) => Build23OwnerControlCenterScreen(\n            onOpenCreatorStudio: () => _openPersonalCreatorStudio(currentProfile),\n          ),\n        ),\n      );\n      return;\n    }\n    _openPersonalCreatorStudio(currentProfile);\n  }`,
      'owner routing revalidation at tap time',
    )
    source = replaceExact(
      source,
      `            onCreatorStudio: () => _openCreatorStudio(profile),`,
      `            onCreatorStudio: () => unawaited(_openCreatorStudio(profile)),`,
      'async owner routing callback',
    )
    changed = true
  }

  await write(path, source)
}

// PATCH C — Owner Settings must plainly expose Owner Control Center instead of
// looking like the same regular Creator Studio entry.
{
  const path = 'native/flutter_v1/lib/features/profile/native_profile_build23.dart'
  let source = await read(path)
  if (!source.includes("label: isOwner ? 'Owner Control Center' : 'Creator Studio'")) {
    source = replaceExact(
      source,
      `                _RowItem(\n                  label: 'Creator Studio',\n                  value: isOwner`,
      `                _RowItem(\n                  label: isOwner ? 'Owner Control Center' : 'Creator Studio',\n                  value: isOwner`,
      'owner settings control-center label',
    )
    changed = true
    await write(path, source)
  }
}

console.log(
  changed
    ? '[build23-final-patch] Applied startup/identity patches; formatter will persist them.'
    : '[build23-final-patch] Startup/identity patches already present.',
)
