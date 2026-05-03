import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'live_room.freezed.dart';

@freezed
abstract class LiveRoom with _$LiveRoom {
  const factory LiveRoom({
    required int id,
    required String title,
    required String coverUrl,
    required bool isLive,
    required String cateName,
    required int uid,
    required String uname,
  }) = _LiveRoom;
}
