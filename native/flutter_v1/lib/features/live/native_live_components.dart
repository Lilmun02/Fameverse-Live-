import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_gift_visual.dart';

class FvLiveChatMessage {
  const FvLiveChatMessage({
    required this.id,
    required this.user,
    required this.text,
    this.userId,
    this.gifterLevel = 1,
    this.kind = 'comment',
    this.giftId,
    this.quantity = 1,
  });

  final String id;
  final String user;
  final String? userId;
  final int gifterLevel;
  final String text;
  final String kind;
  final String? giftId;
  final int quantity;
}

class FvGiftPlayback {
  const FvGiftPlayback({
    required this.gift,
    required this.quantity,
    required this.sender,
    this.comboIndex = 1,
    this.comboTotal = 1,
    this.completionMessage,
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
  final int comboIndex;
  final int comboTotal;

  /// Render one combined chat receipt only after the last combo animation.
  final FvLiveChatMessage? completionMessage;

  String get visualCountLabel {
    if (comboTotal > 1) return ' · Combo ×$comboIndex';
    if (quantity > 1) return ' · ×$quantity';
    return '';
  }
}

const int fvMaxSequentialGiftCombo = 50;

List<FvGiftPlayback> fvExpandGiftVisualCombo(FvGiftPlayback playback) {
  if (playback.quantity <= 1 || playback.quantity > fvMaxSequentialGiftCombo) {
    return <FvGiftPlayback