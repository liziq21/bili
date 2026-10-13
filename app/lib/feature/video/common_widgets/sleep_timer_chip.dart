import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../player/media_playback_controller.dart';

/// 睡眠定时器档位（分钟）。
const List<int> kSleepTimerMinutes = [15, 30, 45, 60];

/// 睡眠定时器状态机：倒计时归零时暂停播放。
///
/// 单独存在是为了让倒计时逻辑可以被单元测试直接驱动，不必渲染 UI。
/// 计时器在 [MediaPlaybackController.pause] 被调用后自动取消。
class SleepTimerController(final MediaPlaybackController _controller)
    extends ChangeNotifier {
  Timer? _timer;

  /// 剩余时间，未启动时为 null。
  Duration? _remaining;

  Duration? get remaining => _remaining;

  /// 启动时选中的档位（分钟），用于弹窗标记当前项。
  int? _selectedMinutes;

  int? get selectedMinutes => _selectedMinutes;

  /// 是否正在计时。
  bool get isActive => _timer != null;

  /// 按分钟启动倒计时。
  void start(int minutes) {
    cancel();
    _selectedMinutes = minutes;
    _remaining = Duration(minutes: minutes);
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    final remaining = _remaining;
    if (remaining == null) {
      timer.cancel();
      return;
    }
    final next = remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      // 到点：暂停并取消，不清档位标记，让弹窗显示上次选择。
      _remaining = null;
      _controller.pause();
      timer.cancel();
      _timer = null;
      notifyListeners();
      return;
    }
    _remaining = next;
    notifyListeners();
  }

  /// 取消计时。档位标记一并清掉，与「未启动」状态对齐。
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _selectedMinutes = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 睡眠定时按钮：未启动时显示「定时」，启动后显示剩余时间。
///
/// 点击弹底部选择器：未启动时列档位，启动后额外提供「取消定时」。
class const SleepTimerChip({
  super.key,
  required final MediaPlaybackController controller,
}) extends StatefulWidget {
  @override
  State<SleepTimerChip> createState() => _SleepTimerChipState();
}

class _SleepTimerChipState() extends State<SleepTimerChip> {
  late final SleepTimerController _sleep;

  @override
  void initState() {
    super.initState();
    _sleep = SleepTimerController(widget.controller);
    _sleep.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sleep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = _sleep.isActive;
    final label = active
        ? _formatRemaining(_sleep.remaining!)
        : (l10n?.sleepTimerLabel ?? '定时');

    return Material(
      color: active
          ? $styles.colors.accentFill.withValues(alpha: 0.9)
          : $styles.colors.scrim.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: $styles.text.bodySmall.copyWith(
              color: active
                  ? $styles.colors.onAccentFill
                  : $styles.colors.onScrim,
            ),
          ),
        ),
      ),
    );
  }

  String _formatRemaining(Duration remaining) {
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
                child: Text(
                  l10n?.sleepTimerTitle ?? '睡眠定时器',
                  style: $styles.text.bodySmallBold,
                ),
              ),
              for (final minutes in kSleepTimerMinutes)
                ListTile(
                  title: Text('$minutes 分钟'),
                  trailing: minutes == _sleep.selectedMinutes
                      ? Icon(Icons.check, color: $styles.colors.accentText)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _sleep.start(minutes);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              if (_sleep.isActive)
                ListTile(
                  title: Text(
                    l10n?.sleepTimerCancel ?? '取消定时',
                    style: TextStyle(color: $styles.colors.accentText),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _sleep.cancel();
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
