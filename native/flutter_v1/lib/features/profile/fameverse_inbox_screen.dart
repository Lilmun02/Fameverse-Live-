import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/fv_policy_access.dart';
import '../../data/fv_system_inbox_repository.dart';

/// Build 47: system activity inbox, using existing published notices only.
/// Direct messaging and personalized read receipts are separate backend work.
class FameverseInboxScreen extends StatefulWidget {
  const FameverseInboxScreen({
    required this.userId,
    this.policyAccess,
    this.onReviewPolicy,
    this.onOpenPolicies,
    this.repository,
    super.key,
  });

  final String userId;
  final FvPolicyAccess? policyAccess;
  final VoidCallback? onReviewPolicy;
  final VoidCallback? onOpenPolicies;
  final FvSystemInboxRepository? repository;

  @override
  State<FameverseInboxScreen> createState() => _FameverseInboxScreenState();
}

class _FameverseInboxScreenState extends State<FameverseInboxScreen> {
  late FvSystemInboxRepository _repository;
  List<FvSystemNotice> _notices = const [];
  String? _error;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        SupabaseFvSystemInboxRepository(Supabase.instance.client);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant FameverseInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.rep