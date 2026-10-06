part of 'native_live_components.dart';

class NativeProfileAvatar extends StatelessWidget {
  const NativeProfileAvatar({
    required this.profile,
    this.radius = 18,
    super.key,
  });

  final FvProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;
    return CircleAvatar(
      radius: radius,
      foregroundImage: avatar != null && avatar.isNotEmpty
          ? NetworkImage(avatar)
          : null,
      child: Text(profile.initial),
    );
  }
}
