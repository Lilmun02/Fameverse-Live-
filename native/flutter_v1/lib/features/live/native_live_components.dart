import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/fameverse_backend.dart';
import '../../data/fameverse_live_backend.dart';
import 'native_gift_visual.dart';
part 'native_gift_overlay.part.dart';
part 'native_gift_tray.part.dart';
part 'native_gift_balance.part.dart';
part 'native_profile_avatar.part.dart';


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
  });

  final FvGiftDefinition gift;
  final int quantity;
  final String sender;
  final int comboIndex;
  final int comboTotal;

  String get visualCountLabel {
    if (comboTotal > 1) return ' · Combo ×$comboIndex';
    if (quantity > 1) return ' · ×$quantity';
    return '';
  }
}

const int fvMaxSequentialGiftCombo = 50;

List<FvGiftPlayback> fvExpandGiftVisualCombo(FvGiftPlayback playback) {
  if (playback.quantity <= 1 || playback.quantity > fvMaxSequentialGiftCombo) {
    return <FvGiftPlayback>[playback];
  }

  return List<FvGiftPlayback>.generate(
    playback.quantity,
    (index) => FvGiftPlayback(
      gift: playback.gift,
      quantity: 1,
      sender: playback.sender,
      comboIndex: index + 1,
      comboTotal: playback.quantity,
    ),
    growable: false,
  );
}
