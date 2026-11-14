import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/fameverse_beta_backend.dart';

class FirstVerseBetaScreen extends StatefulWidget {
  const FirstVerseBetaScreen({this.backend, super.key});

  final FameverseBetaBackend? backend;

  @override
  State<FirstVerseBetaScreen> createState() => _FirstVerseBetaScreenState();
}

class _FirstVerseBetaScreenState extends State<FirstVerseBetaScreen> {
  late final FameverseBetaBackend _backend;
  FvBetaProgramStatus? _status;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _backend = widget.backend ?? SupabaseFameverseBetaBackend.instance;
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final status = await _backend.loadProgramStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Beta progress could not load. Pull to try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      key: const Key('first-verse-beta-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'First Verse',
          style: Tex