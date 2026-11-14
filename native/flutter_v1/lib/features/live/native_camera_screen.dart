import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_live_components.dart';
import 'stream_live_screen.dart';

class NativeCameraScreen extends StatefulWidget {
  const NativeCameraScreen({
    required this.liveBackend,
    required this.identity,
    required this.profile,
    required this.onLiveEnded,
    super.key,
  });

  final FameverseLiveBackend liveBackend;
  final FvIdentity identity;
  final FvProfile profile;
  final Future<void> Function() onLiveEnded;

  @override
  State<NativeCameraScreen> createState() => _NativeCameraScreenState();
}

class _NativeCameraScreenState extends State<NativeCameraScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _goal = TextEditingController();
  CameraController? _permissionProbe;
  CameraController? _previewController;
  Future<void>? _previewInitialization;
  String? _previewError;
  bool _loadingDraft = true;
  bool _liveBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    final controller = _permissionProbe;
    _permissionProbe = null;
    if (controller != null) unawaited(controller.dispose());
    final preview = _previewController;
    _previewController = null;
    if 