import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../setting/app_settings.dart';
import '../player/media_playback_controller.dart';

/// 键盘一次调整的音量步长。
const double kVolumeStep = 0.05;

/// 方向键快进/快退的步长，按住 Shift 时用长步长。
const Duration kKeyboardSeekStep = Duration(seconds: 5);

/// 配合 Shift 的长步长。
const Duration kKeyboardSeekStepLong = Duration(seconds: 10);

/// 播放器桌面键盘动作。
enum PlayerKeyboardAction() {
  togglePlayback,
  seekBackward,
  seekForward,
  volumeUp,
  volumeDown,
  toggleFullscreen,
  toggleMute,
  slower,
  faster,
}

/// 把逻辑键映射成播放器动作，供 UI 和单测共用同一份映射表。
PlayerKeyboardAction? playerKeyboardActionFor(LogicalKeyboardKey key) =>
    switch (key) {
      LogicalKeyboardKey.space => PlayerKeyboardAction.togglePlayback,
      LogicalKeyboardKey.arrowLeft => PlayerKeyboardAction.seekBackward,
      LogicalKeyboardKey.arrowRight => PlayerKeyboardAction.seekForward,
      LogicalKeyboardKey.arrowUp => PlayerKeyboardAction.volumeUp,
      LogicalKeyboardKey.arrowDown => PlayerKeyboardAction.volumeDown,
      LogicalKeyboardKey.keyF => PlayerKeyboardAction.toggleFullscreen,
      LogicalKeyboardKey.keyM => PlayerKeyboardAction.toggleMute,
      LogicalKeyboardKey.bracketLeft => PlayerKeyboardAction.slower,
      LogicalKeyboardKey.bracketRight => PlayerKeyboardAction.faster,
      _ => null,
    };

/// 桌面端键盘与鼠标滚轮映射。
///
/// 键位：
/// - `空格` 播放 / 暂停
/// - `←` `→` 快退 / 快进 5 秒，按住 Shift 为 10 秒
/// - `↑` `↓` 音量 ±5%
/// - `M` 静音切换（再次按下恢复静音前的音量）
/// - `F` 进入 / 退出全屏
/// - `[` `]` 倍速降 / 升一档
///
/// 鼠标滚轮同样调音量，与常见桌面播放器一致。鼠标双击全屏在
/// [PlayerGestureLayer] 内处理，不在本组件——那里才有手势竞技场。
class const PlayerKeyboardShortcuts({
  super.key,
  required final MediaPlaybackController controller,
  required final VoidCallback? onToggleFullscreen,
  final Duration seekStep = kKeyboardSeekStep,
  final Duration seekStepWithShift = kKeyboardSeekStepLong,
  final double volumeStep = kVolumeStep,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<PlayerKeyboardShortcuts> createState() =>
      _PlayerKeyboardShortcutsState();
}

class _PlayerKeyboardShortcutsState() extends State<PlayerKeyboardShortcuts> {
  /// 静音前的音量，供再次按 M 时恢复。
  ///
  /// 静音不是把音量记成 0 就完事：那样第二次按 M 只能回到 0，用户得重新调。
  double _volumeBeforeMute = 1.0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Listener(onPointerSignal: _onPointerSignal, child: widget.child),
    );
  }

  /// 只处理按下事件：长按重复触发会让快进变成连续跳。
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final state = widget.controller.state;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    switch (playerKeyboardActionFor(event.logicalKey)) {
      case PlayerKeyboardAction.togglePlayback:
        widget.controller.playOrPause();
        return KeyEventResult.handled;
      case PlayerKeyboardAction.seekBackward:
        _seekTo(
          state.position - (shift ? widget.seekStepWithShift : widget.seekStep),
        );
        return KeyEventResult.handled;
      case PlayerKeyboardAction.seekForward:
        _seekTo(
          state.position + (shift ? widget.seekStepWithShift : widget.seekStep),
        );
        return KeyEventResult.handled;
      case PlayerKeyboardAction.volumeUp:
        _setVolume(state.volume + widget.volumeStep);
        return KeyEventResult.handled;
      case PlayerKeyboardAction.volumeDown:
        _setVolume(state.volume - widget.volumeStep);
        return KeyEventResult.handled;
      case PlayerKeyboardAction.toggleMute:
        _toggleMute(state.volume);
        return KeyEventResult.handled;
      case PlayerKeyboardAction.toggleFullscreen:
        widget.onToggleFullscreen?.call();
        return KeyEventResult.handled;
      case PlayerKeyboardAction.slower:
        _stepRate(-1);
        return KeyEventResult.handled;
      case PlayerKeyboardAction.faster:
        _stepRate(1);
        return KeyEventResult.handled;
      case null:
        return KeyEventResult.ignored;
    }
  }

  /// 滚轮调音量：向下滚变小，向上滚变大。
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    // 向下滚（dy 正）降低，与常见桌面播放器一致。
    _setVolume(
      widget.controller.state.volume -
          (delta > 0 ? widget.volumeStep : -widget.volumeStep),
    );
  }

  void _seekTo(Duration target) {
    final duration = widget.controller.state.duration;
    final ms = duration > Duration.zero
        ? target.inMilliseconds.clamp(0, duration.inMilliseconds).toInt()
        : target.inMilliseconds.clamp(0, 1 << 31).toInt();
    widget.controller.seek(Duration(milliseconds: ms));
  }

  void _setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    // 调过音量就作废静音前的快照，否则取消静音会跳回旧值。
    if (clamped > 0) _volumeBeforeMute = clamped;
    widget.controller.setVolume(clamped);
  }

  void _toggleMute(double currentVolume) {
    if (currentVolume > 0) {
      _volumeBeforeMute = currentVolume;
      widget.controller.setVolume(0);
      return;
    }
    widget.controller.setVolume(_volumeBeforeMute);
  }

  /// 在 [kPlaybackRates] 里升降一档；当前不在档位表里时先落到 1.0，再按 delta 走。
  void _stepRate(int delta) {
    final current = widget.controller.state.rate;
    var index = kPlaybackRates.indexOf(current);
    if (index < 0) index = kPlaybackRates.indexOf(1.0);
    index += delta;
    final next = kPlaybackRates[index.clamp(0, kPlaybackRates.length - 1)];
    widget.controller.setRate(next);
  }
}
