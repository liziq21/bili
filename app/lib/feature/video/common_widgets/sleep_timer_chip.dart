import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../design/design.dart';
import '../../../domain/sleep_timer_action.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../notification/sleep_timer_notifier.dart';
import '../../setting/app_settings.dart' as settings;
import '../../setting/sleep_timer_duration_dialog.dart';
import '../player/media_playback_controller.dart';

/// Backwards-compatible export for the player chip's duration list.
const kSleepTimerMinutes = settings.kSleepTimerMinutes;

/// 睡眠定时器状态机：倒计时归零时按 [SleepTimerAction] 停播。
///
/// 单独存在是为了让倒计时逻辑可以被单元测试直接驱动，不必渲染 UI。
/// 计时器在 [MediaPlaybackController.pause] 被调用后自动取消。
class SleepTimerController(
  final MediaPlaybackController _controller, {

  /// 剩余时间进入最后一分钟时回调一次；总时长不超过一分钟时不回调。
  final Future<void> Function()? onEndingSoon,

  /// [SleepTimerAction.exitPlayer] 到点时回调，用于关闭播放器。
  final VoidCallback? onExitPlayer,
}) extends ChangeNotifier {
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

  /// 本次倒计时的总时长，用来判断是否值得发「最后一分钟」提醒。
  Duration _total = Duration.zero;

  bool _warned = false;

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
    _total = Duration(minutes: minutes);
    _remaining = _total;
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
    _maybeWarnEndingSoon(next);
    if (next <= Duration.zero) {
      // 到点：不清档位标记，让弹窗显示上次选择。
      _remaining = null;
      timer.cancel();
      _timer = null;
      switch (_action) {
        case SleepTimerAction.pauseNow:
          _controller.pause();
        case SleepTimerAction.afterCurrent:
          _pendingStop = true;
        case SleepTimerAction.exitPlayer:
          _controller.pause();
          onExitPlayer?.call();
      }
      notifyListeners();
      return;
    }
    _remaining = next;
    notifyListeners();
  }

  /// 剩余时间进入最后一分钟时提醒一次。
  ///
  /// 总时长本来就不到一分钟时立刻提醒没有意义，故只在 [_total] 更长时触发。
  /// `afterCurrent` 到点并不会立刻停播，提醒「一分钟后停止」会是假消息。
  void _maybeWarnEndingSoon(Duration next) {
    if (_warned ||
        _action == SleepTimerAction.afterCurrent ||
        _total <= const Duration(minutes: 1) ||
        next > const Duration(minutes: 1) ||
        next <= Duration.zero) {
      return;
    }
    _warned = true;
    unawaited(onEndingSoon?.call() ?? Future<void>.value());
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
    _total = Duration.zero;
    _warned = false;
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
/// 点击弹底部选择器：先选到点行为，再选时长；启动后额外提供「取消定时」。
class const SleepTimerChip({
  super.key,
  required final MediaPlaybackController controller,

  /// 到点行为为「关闭播放器」时调用。缺省时不离开页面，只暂停播放。
  final VoidCallback? onExit,
}) extends StatefulWidget {
  @override
  State<SleepTimerChip> createState() => _SleepTimerChipState();
}

class _SleepTimerChipState() extends State<SleepTimerChip> {
  late final SleepTimerController _sleep;
  PreferencesDataSource? _preferences;
  SleepTimerNotifier? _notifier;
  bool _userSelected = false;
  bool _permissionRequested = false;

  /// 下一次启动计时使用的到点行为；由持久化默认值初始化。
  SleepTimerAction _pendingAction = SleepTimerAction.pauseNow;

  @override
  void initState() {
    super.initState();
    _sleep = SleepTimerController(
      widget.controller,
      onEndingSoon: _notifyEndingSoon,
      onExitPlayer: widget.onExit,
    );
    _sleep.addListener(() {
      if (mounted) setState(() {});
    });
    try {
      _preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {}
    try {
      _notifier = context.read<SleepTimerNotifier>();
    } on Object catch (_) {}
    _restoreDefaultTimer();
  }

  Future<void> _notifyEndingSoon() async {
    await _notifier?.notifyEndingSoon();
  }

  Future<void> _restoreDefaultTimer() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final loaded = await settings.PlayerSettings.load(preferences);
    if (!mounted || _userSelected) return;
    _pendingAction = loaded.sleepTimerDefaultAction;
    if (!settings.isValidSleepTimerMinutes(loaded.sleepTimerDefaultMinutes)) {
      return;
    }
    _sleep.start(
      loaded.sleepTimerDefaultMinutes,
      action: loaded.sleepTimerDefaultAction,
    );
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

  String _actionLabel(AppLocalizations? l10n, SleepTimerAction action) =>
      switch (action) {
        SleepTimerAction.pauseNow =>
          l10n?.sleepTimerActionNowLabel ?? 'Pause now',
        SleepTimerAction.afterCurrent =>
          l10n?.sleepTimerAfterCurrentTitle ?? 'After current video',
        SleepTimerAction.exitPlayer =>
          l10n?.sleepTimerActionExitPlayerLabel ?? 'Close player',
      };

  void _showPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => SafeArea(
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
                _groupLabel(
                  l10n?.playerSleepTimerAction ?? 'When the sleep timer ends',
                ),
                for (final action in SleepTimerAction.values)
                  _option(
                    _actionLabel(l10n, action),
                    selected: action == _pendingAction,
                    onTap: () => setSheetState(() => _pendingAction = action),
                  ),
                _groupLabel(l10n?.sleepTimerDuration ?? 'Duration'),
                for (final minutes in kSleepTimerMinutes)
                  _option(
                    l10n?.minutesValue('$minutes') ?? '$minutes min',
                    selected:
                        minutes == _sleep.selectedMinutes &&
                        _sleep.action == _pendingAction,
                    onTap: () => _pick(sheetContext, minutes, _pendingAction),
                  ),
                _customOption(sheetContext),
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
        ? Icon(AppIcons.check, color: $styles.colors.accentText)
        : null,
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
  );

  Widget _customOption(BuildContext sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final selectedMinutes = _sleep.selectedMinutes;
    final selected =
        selectedMinutes != null &&
        !kSleepTimerMinutes.contains(selectedMinutes) &&
        _sleep.action == _pendingAction;
    return _option(
      selected
          ? (l10n?.sleepTimerCustomValue('$selectedMinutes') ??
                '$selectedMinutes min')
          : (l10n?.sleepTimerCustom ?? 'Custom'),
      selected: selected,
      onTap: () => unawaited(_showCustomDuration(sheetContext)),
    );
  }

  Future<void> _showCustomDuration(BuildContext sheetContext) async {
    final l10n = AppLocalizations.of(sheetContext);
    final minutes = await showDialog<int>(
      context: sheetContext,
      builder: (_) => SleepTimerDurationDialog(
        title: l10n?.sleepTimerCustomTitle ?? 'Custom duration',
        minutesLabel: l10n?.sleepTimerMinutesHint ?? 'Minutes',
        invalidDurationMessage:
            l10n?.sleepTimerInvalidDuration ??
            'Enter a duration from 1 to 1440 minutes.',
        cancelLabel: l10n?.dialogCancel ?? 'Cancel',
        confirmLabel: l10n?.confirm ?? 'OK',
        minMinutes: settings.kMinSleepTimerMinutes,
        maxMinutes: settings.kMaxSleepTimerMinutes,
      ),
    );
    if (!mounted || !sheetContext.mounted || minutes == null) return;
    _pick(sheetContext, minutes, _pendingAction);
  }

  void _pick(BuildContext sheetContext, int minutes, SleepTimerAction action) {
    _userSelected = true;
    _pendingAction = action;
    _sleep.start(minutes, action: action);
    if (!_permissionRequested) {
      _permissionRequested = true;
      unawaited(_notifier?.requestPermission());
    }
    Navigator.of(sheetContext).pop();
  }
}
