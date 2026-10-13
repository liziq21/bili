import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../player/brightness_service.dart';
import '../player/media_playback_controller.dart';
import 'playback_speed_chip.dart';

/// 播放器手势层：在画面上接管水平快进、两侧垂直滑动与长按加速。
///
/// 单独存在是为了让手势回调可以被 widget 测试直接驱动（暴露
/// [gestureHandlers]），不必渲染原生 `Video`；同时把快进目标时间与
/// 音量/亮度的指示浮层集中在本组件内渲染。
///
/// 手势职责划分：
/// - 水平拖动：快进/快退，松手才 seek，拖动中显示目标时间浮层
/// - 右半侧垂直拖动：音量，向下拉减小
/// - 左半侧垂直拖动：屏幕亮度（经 [BrightnessService]），向下拉减小
/// - 长按：临时 2x，由 [BoostRateController] 承载
class const PlayerGestureLayer({
  super.key,
  required final MediaPlaybackController controller,
  required final BrightnessService brightnessService,
  required final BoostRateController boost,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState() extends State<PlayerGestureLayer> {
  /// 快进拖动中的目标位置，不在拖动时为 null。
  Duration? _seekTarget;

  /// 快进拖动起点（画面位置与时间）。
  Offset? _seekStart;
  Duration? _seekBase;
  double _seekPerPixel = 0;

  /// 垂直拖动状态。isVolume 为 true 调音量，false 调亮度。
  _VerticalDrag? _vertical;

  /// 上次读到的窗口亮度，拖动起点。
  double _brightness = 0.5;

  @override
  void initState() {
    super.initState();
    _refreshBrightness();
  }

  Future<void> _refreshBrightness() async {
    final value = await widget.brightnessService.getBrightness();
    if (!mounted) return;
    // -1 与 null 都表示跟随系统或读取失败，用中性值做起拖点。
    if (value != null && value >= 0) {
      _brightness = value;
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    final state = widget.controller.state;
    _seekBase = state.position;
    _seekStart = details.localPosition;
    // 整屏水平拖动约扫过两倍时长，长短视频手感一致。
    final width = context.size?.width ?? 1;
    final durationMs = state.duration.inMilliseconds;
    _seekPerPixel = durationMs > 0 ? (durationMs / width) * 2 : 400.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final base = _seekBase;
    if (base == null || _seekStart == null) return;
    final dx = details.localPosition.dx - _seekStart!.dx;
    final targetMs = base.inMilliseconds + dx * _seekPerPixel;
    final duration = widget.controller.state.duration;
    final clamped = Duration(
      milliseconds: targetMs.round().clamp(0, duration.inMilliseconds),
    );
    if (clamped != _seekTarget) {
      HapticFeedback.selectionClick();
      setState(() => _seekTarget = clamped);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final target = _seekTarget;
    _seekBase = null;
    _seekStart = null;
    setState(() => _seekTarget = null);
    if (target != null) {
      HapticFeedback.mediumImpact();
      widget.controller.seek(target);
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final width = context.size?.width ?? 1;
    final isVolume = details.localPosition.dx >= width / 2;
    if (isVolume) {
      _vertical = _VerticalDrag(
        isVolume: true,
        value: widget.controller.state.volume,
      );
    } else {
      _vertical = _VerticalDrag(isVolume: false, value: _brightness);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final vertical = _vertical;
    if (vertical == null) return;
    final height = context.size?.height ?? 1;
    // 向下拖（正 dy）减小，与「下拉降低」的直觉一致。
    final delta = -details.delta.dy / height;
    final value = (vertical.value + delta).clamp(0.0, 1.0);
    if (value != vertical.value) {
      vertical.value = value;
      if (vertical.isVolume) {
        widget.controller.setVolume(value);
      } else {
        widget.brightnessService.setBrightness(value);
        _brightness = value;
      }
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_vertical case final vertical?) {
      if (!vertical.isVolume) {
        // 亮度跟随系统时不留在 0：拖到最低附近恢复跟随系统，避免锁死最暗。
        if (vertical.value <= 0.02) {
          widget.brightnessService.setBrightness(null);
          _brightness = 0.5;
        }
      }
    }
    setState(() => _vertical = null);
  }

  /// 暴露给 widget 测试直接驱动：不经过手势竞技场也能验证状态机。
  PlayerGestureHandlers get gestureHandlers => PlayerGestureHandlers(
    onHorizontalDragUpdate: _onHorizontalDragUpdate,
    onHorizontalDragEnd: _onHorizontalDragEnd,
    onVerticalDragStart: _onVerticalDragStart,
    onVerticalDragUpdate: _onVerticalDragUpdate,
    onVerticalDragEnd: _onVerticalDragEnd,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onLongPress: widget.boost.onLongPress,
                onLongPressEnd: (_) => widget.boost.onLongPressEnd(),
                child: widget.child,
              ),
            ),
            if (_seekTarget != null)
              Positioned.fill(
                child: _SeekIndicator(
                  target: _seekTarget!,
                  position: widget.controller.state.position,
                  duration: widget.controller.state.duration,
                ),
              ),
            if (_vertical != null)
              Positioned.fill(child: _VerticalIndicator(vertical: _vertical!)),
          ],
        );
      },
    );
  }
}

/// 垂直拖动的可变状态：拖动中持续改写 [value]，松手前不落库。
class _VerticalDrag {
  // value 需在拖动中改写，primary constructor 只能生成 final 字段。
  // ignore: use_primary_constructors, unnecessary_type_name_in_constructor
  _VerticalDrag({required this.isVolume, required this.value});

  final bool isVolume;
  double value;
}

/// 快进目标时间浮层：显示增量与落点时间。
class const _SeekIndicator({
  required final Duration target,
  required final Duration position,
  required final Duration duration,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final delta = target - position;
    final sign = delta.isNegative ? '-' : '+';
    final absDelta = delta.abs();

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: $styles.colors.scrim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$sign${_formatDuration(absDelta)}',
              style: $styles.text.bodySmallBold.copyWith(
                color: $styles.colors.onScrim,
              ),
            ),
            const Gap(4),
            Text(
              '${_formatDuration(target)} / ${_formatDuration(duration)}',
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onScrim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

/// 音量/亮度调节指示：中央百分比 + 图标。
class const _VerticalIndicator({required final _VerticalDrag vertical})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final percent = (vertical.value * 100).round();
    final icon = vertical.isVolume
        ? _volumeIcon(vertical.value)
        : Icons.brightness_6_outlined;

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: $styles.colors.scrim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: $styles.colors.onScrim, size: 28),
            const Gap(6),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: vertical.value,
                color: $styles.colors.accentFill,
                backgroundColor: $styles.colors.onScrim.withValues(alpha: 0.3),
              ),
            ),
            const Gap(6),
            Text(
              '$percent%',
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onScrim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _volumeIcon(double value) {
    if (value <= 0) return Icons.volume_off;
    if (value < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }
}

/// 手势回调集合，供 widget 测试直接驱动。
class const PlayerGestureHandlers({
  required final void Function(DragUpdateDetails details)
  onHorizontalDragUpdate,
  required final void Function(DragEndDetails details) onHorizontalDragEnd,
  required final void Function(DragStartDetails details) onVerticalDragStart,
  required final void Function(DragUpdateDetails details) onVerticalDragUpdate,
  required final void Function(DragEndDetails details) onVerticalDragEnd,
});
