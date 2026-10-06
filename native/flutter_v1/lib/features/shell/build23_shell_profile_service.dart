import 'package:image_picker/image_picker.dart';

import '../../data/fameverse_backend.dart';

class FvBuild23ShellProfileService {
  const FvBuild23ShellProfileService({
    required this.backend,
    required this.userId,
  });

  final FameverseBackend backend;
  final String userId;

  Future<FvProfile> save({
    required String displayName,
    required String username,
    required String bio,
  }) {
    return backend.saveProfile(
      userId: userId,
      displayName: displayName,
      username: username,
      bio: bio,
    );
  }

  Future<FvProfile?> pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picked == null) return null;

    final extension = _avatarExtension(picked.name);
    return backend.uploadProfileAvatar(
      userId: userId,
      bytes: await picked.readAsBytes(),
      extension: extension,
      contentType: _avatarContentType(extension),
    );
  }

  String _avatarExtension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _avatarContentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
