import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../profile/fameverse_edit_profile_screen.dart';
import '../profile/fameverse_policy_screen.dart';

class FvBuild23ShellNavigation {
  const FvBuild23ShellNavigation();

  void message(BuildContext context, String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  void openPolicies(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const FameversePolicyScreen()),
    );
  }

  void openEdit(
    BuildContext context, {
    required FvProfile profile,
    required bool avatarBusy,
    required VoidCallback onChangePhoto,
    required Future<void> Function({
      required String displayName,
      required String username,
      required String bio,
    })
    onSave,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FameverseEditProfileScreen(
          profile: profile,
          avatarBusy: avatarBusy,
          onChangePhoto: onChangePhoto,
          onSave: onSave,
        ),
      ),
    );
  }
}
