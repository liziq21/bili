import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../setting/app_settings.dart' as settings;
import '../player/media_playback_controller.dart';

/// Backwards-compatible export for the player chip's duration list.
const kSleepTimerMinutes = settings.kSleepTimerMinutes;

/// 计时归零时的行为。
enum SleepTimerAction() {
  /// 归零即暂停当前播放。
  pauseNow,

  /// 本条照播完，等队列要进下一条时再暂停。
  ///
  /// 队列循环 / 单曲循环下媒体播完会自动进下一条，故到点本身不干预，
  /// 真正的停点在 [PlaybackState.currentIndex] 变化的那一刻。
  afterCurrent,
}

/// 睡眠定时器状态机：倒计时归零时按 [SleepTimerAction] 停播。
///
/// 单独存在是为了让倒计时逻辑可以被单元测试直接驱动，不必渲染 UI。
/// 计时器在 [MediaPlaybackController.pause] 被调用后自动取消。
class SleepTimerController(final MediaPlaybackController _controller)
    extends ChangeNotifier {
  this {
    _subscription = _controller.states.listen(_onState);
  }

  Timer? _timer;
  StreamSubscription<PlaybackState>? _subscription;

  /// 剩余时间，未启动时为 null。
  Duration? _remaining;

  Duration? get remaining => _remaining;

  /// 启动时选中的档位（分钟），用于弹窗标记当前项。
  int? _selectedMinutes;

  int? get selectedMinutes => _selectedMinutes;

  /// 启动时选择的归零行为，用于弹窗标记当前项。
  SleepTimerAction get action => _action;
  SleepTimerAction _action = SleepTimerAction.pauseNow;

  /// 计时已归零、但要等当前这条播完才真正停。
  bool get pendingAfterCurrent => _pendingStop;
  bool _pendingStop = false;

  /// 最近一次读到的队列序号，用来判定「要进下一条了」。
  int _queueIndex = 0;

  /// 是否正在计时或等待生效。
  bool get isActive => _timer != null || _pendingStop;

  /// 按分钟启动倒计时。
  void start(
    int minutes, {
    SleepTimerAction action = SleepTimerAction.pauseNow,
  }) {
    cancel();
    _selectedMinutes = minutes;
    _action = action;
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
      // 到点：不清档位标记，让弹窗显示上次选择。
      _remaining = null;
      timer.cancel();
      _timer = null;
      if (_action == SleepTimerAction.afterCurrent) {
        _pendingStop = true;
      } else {
        _controller.pause();
      }
      notifyListeners();
      return;
    }
    _remaining = next;
    notifyListeners();
  }

  /// 队列序号前进时，若处于「播完这条再停」就停住，不再进入下一条。
  ///
  /// 只在有队列时判定：单条播放播完本就自然停下，无需也不该再插一次
  /// pause——否则用户手动暂停会被误当成播完。
  void _onState(PlaybackState state) {
    if (state.queueLength <= 0) return;
    if (!_pendingStop) {
      _queueIndex = state.currentIndex;
      return;
    }
    if (state.currentIndex != _queueIndex) {
      _pendingStop = false;
      unawaited(_controller.pause());
      notifyListeners();
      return;
    }
    _queueIndex = state.currentIndex;
  }

  /// 取消计时。档位标记与待生效标记一并清掉，与「未启动」状态对齐。
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _selectedMinutes = null;
    _pendingStop = false;
    _action = SleepTimerAction.pauseNow;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// 睡眠定时按钮：未启动时显示「定时」，启动后显示剩余时间或待生效标记。
///
/// 点击弹底部选择器：按归零行为分两组列档位，启动后额外提供「取消定时」。
class const SleepTimerChip({
  super.key,
  required final MediaPlaybackController controller,
}) extends StatefulWidget {
  @override
  State<SleepTimerChip> createState() => _SleepTimerChipState();
}

class _SleepTimerChipState() extends State<SleepTimerChip> {
  late final SleepTimerController _sleep;
  PreferencesDataSource? _preferences;
  bool _userSelected = false;

  @override
  void initState() {
    super.initState();
    _sleep = SleepTimerController(widget.controller);
    _sleep.addListener(() {
      if (mounted) setState(() {});
    });
    try {
      _preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {}
    _restoreDefaultTimer();
  }

  Future<void> _restoreDefaultTimer() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final result = await preferences.get(
      PreferencesKey.sleepTimerDefaultMinutes,
    );
    if (!mounted || _userSelected) return;
    switch (result) {
      case Ok(:final value)
          when value > 0 && kSleepTimerMinutes.contains(value):
        _sleep.start(value);
      case Ok() || Error():
        break;
    }
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
    final label = _sleep.pendingAfterCurrent
        ? (l10n?.afterCurrentItem ?? 'After current')
        : active
        ? _formatRemaining(_sleep.remaining!)
        : (l10n?.timer ?? 'Timer');
    final timerTitle = l10n?.sleepTimerTitle ?? 'Sleep timer';

    return Tooltip(
      message: timerTitle,
      child: Semantics(
        button: true,
        label: '$timerTitle $label',
        excludeSemantics: true,
        child: Material(
          color: active
              ? $styles.colors.accentFill.withValues(alpha: 0.9)
              : $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _userSelected = true;
              _showPicker(context);
            },
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
                  l10n?.sleepTimerTitle ?? 'Sleep timer',
                  style: $styles.text.bodySmallBold,
                ),
              ),
              _groupLabel(l10n?.pauseWhenTimeUp ?? 'When time up'),
              for (final minutes in kSleepTimerMinutes)
                _option(
                  l10n?.minutesValue('$minutes') ?? '$minutes min',
                  selected:
                      minutes == _sleep.selectedMinutes &&
                      !_sleep.pendingAfterCurrent &&
                      _sleep.action == SleepTimerAction.pauseNow,
                  onTap: () =>
                      _pick(sheetContext, minutes, SleepTimerAction.pauseNow),
                ),
              _groupLabel(l10n?.stopAfterCurrentItem ?? 'Stop after current'),
              for (final minutes in kSleepTimerMinutes)
                _option(
                  // 两组都用「N 分钟」会让文案完全相同，分组标题之外再无区分，
                  // 故本组加后缀。
                  '${l10n?.minutesWithSuffix('$minutes') ?? '$minutes min'}${l10n?.sleepTimerAfterCurrentOptionSuffix ?? ' (after current)'}',
                  selected:
                      minutes == _sleep.selectedMinutes &&
                      _sleep.pendingAfterCurrent,
                  onTap: () => _pick(
                    sheetContext,
                    minutes,
                    SleepTimerAction.afterCurrent,
                  ),
                ),
              if (_sleep.isActive)
                ListTile(
                  title: Text(
                    l10n?.cancelTimer ?? 'Cancel',
                    style: TextStyle(color: $styles.colors.accentText),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _userSelected = true;
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

  Widget _groupLabel(String text) => Padding(
    padding: EdgeInsets.only(top: $styles.insets.sm, left: $styles.insets.sm),
    child: Text(
      text,
      style: $styles.text.bodySmall.copyWith(
        color: $styles.colors.onSurfaceVariant,
      ),
    ),
  );

  Widget _option(
    String title, {
    required bool selected,
    required VoidCallback onTap,
  }) => ListTile(
    title: Text(title),
    trailing: selected
        ? Icon(Icons.check, color: $styles.colors.accentText)
        : null,
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
  );

  void _pick(BuildContext sheetContext, int minutes, SleepTimerAction action) {
    _userSelected = true;
    _sleep.start(minutes, action: action);
    Navigator.of(sheetContext).pop();
  }
}
