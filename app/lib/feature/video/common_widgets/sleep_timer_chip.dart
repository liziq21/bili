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
/// 生命周期归播放器所有，控制栏重建不会打断倒计时，见 [SleepTimerScope]。
class SleepTimerController(
  final MediaPlaybackController _controller, {

  /// 剩余时间进入最后一分钟时回调一次；总时长不超过一分钟时不回调。
  final Future<void> Function()? onEndingSoon,

  /// [SleepTimerAction.exitPlayer] 到点时回调，用于关闭播放器。
  final VoidCallback? onExitPlayer,

  /// 定时器被取消、重设或释放时回调，用于撤掉已经发出的提醒。
  final VoidCallback? onCanceled,
}) extends ChangeNotifier {
  this {
    // 队列可能已经播到中间，从当前序号起算，避免把「同一条播完」误判成换条。
    _queueIndex = _controller.state.currentIndex;
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
          unawaited(_pause());
        case SleepTimerAction.afterCurrent:
          _pendingStop = true;
        case SleepTimerAction.exitPlayer:
          // 先等暂停落地再关页面：页面一关，控制器随之释放，暂停可能丢。
          unawaited(_pauseThenExit());
      }
      notifyListeners();
      return;
    }
    _remaining = next;
    notifyListeners();
  }

  Future<void> _pause() async {
    try {
      await _controller.pause();
    } on Object catch (_) {
      // 暂停失败不打断定时器流程；关闭页面的动作仍然继续。
    }
  }

  Future<void> _pauseThenExit() async {
    await _pause();
    onExitPlayer?.call();
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
    // 越过最后一分钟这一刻就定性：暂停期间不补发。倒计时照走，恢复播放时
    // 剩余可能已不足一分钟，那时再说「一分钟后停止」就是假消息。
    _warned = true;
    final state = _controller.state;
    if (!state.isPlaying && !state.isBuffering) return;
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
    final hadState = isActive || _warned;
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _selectedMinutes = null;
    _pendingStop = false;
    _action = SleepTimerAction.pauseNow;
    _total = Duration.zero;
    _warned = false;
    if (hadState) onCanceled?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    final hadState = isActive || _warned;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    if (hadState) onCanceled?.call();
    super.dispose();
  }
}

/// 让同一播放器的多个控制栏实例共享一份倒计时状态。
///
/// 全屏切换会重建整条控制栏，全屏控制层自动隐藏也会卸载它。倒计时若跟着
/// 按钮走，每次重建都会把定时器清掉；播放器在控制栏之外持有本作用域，
/// 重建后的按钮从这里取回同一个控制器。
class const SleepTimerScope({
  super.key,
  required final SleepTimerController controller,

  /// 持久化的默认到点行为，用作选择器的初始选中项。
  required final SleepTimerAction defaultAction,

  /// 用户从选择器启动计时后的回调，用于按行为申请通知权限。
  required final ValueChanged<SleepTimerAction> onTimerStarted,
  required super.child,
}) extends InheritedWidget {
  static SleepTimerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SleepTimerScope>();

  @override
  bool updateShouldNotify(SleepTimerScope oldWidget) =>
      controller != oldWidget.controller ||
      defaultAction != oldWidget.defaultAction;
}

/// 睡眠定时按钮：未启动时显示「定时」，启动后显示剩余时间或待生效标记。
///
/// 点击弹底部选择器：先选到点行为，再选时长；启动后额外提供「取消定时」。
/// 播放器通过 [SleepTimerScope] 提供共享控制器；没有作用域时（例如单独测试
/// 这个按钮）由按钮自己创建并释放控制器，并自行恢复默认档位。
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
  /// 当前使用的控制器：来自作用域，或由本按钮创建。
  SleepTimerController? _timer;
  SleepTimerController? _ownedTimer;
  SleepTimerScope? _scope;
  PreferencesDataSource? _preferences;
  SleepTimerNotifier? _notifier;

  /// 自建控制器时本按钮独占的提醒 id；走作用域时由播放器分配。
  final int _notificationId = allocateSleepTimerNotificationId();
  bool _userSelected = false;
  bool _permissionRequested = false;
  bool _restoredDefault = false;

  /// 下一次启动计时使用的到点行为；由持久化默认值初始化。
  SleepTimerAction _pendingAction = SleepTimerAction.pauseNow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = SleepTimerScope.maybeOf(context);
    final timer = scope?.controller ?? (_ownedTimer ??= _createOwnTimer());
    if (!identical(timer, _timer)) {
      _timer?.removeListener(_handleTimerChanged);
      _timer = timer..addListener(_handleTimerChanged);
    }
    _scope = scope;
    if (scope != null) {
      if (!_userSelected) _pendingAction = scope.defaultAction;
      return;
    }
    // 没有作用域时（单独使用本按钮）自行恢复默认档位，只做一次。
    if (!_restoredDefault) {
      _restoredDefault = true;
      unawaited(_restoreDefaultTimer());
    }
  }

  SleepTimerController _createOwnTimer() {
    try {
      _preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {}
    try {
      _notifier = context.read<SleepTimerNotifier>();
    } on Object catch (_) {}
    return SleepTimerController(
      widget.controller,
      onEndingSoon: _notifyEndingSoon,
      onExitPlayer: widget.onExit,
      onCanceled: () => unawaited(_notifier?.cancel(id: _notificationId)),
    );
  }

  void _handleTimerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _notifyEndingSoon() async {
    await _notifier?.notifyEndingSoon(id: _notificationId);
  }

  Future<void> _restoreDefaultTimer() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final loaded = await settings.PlayerSettings.load(preferences);
    if (!mounted) return;
    if (!_userSelected) _pendingAction = loaded.sleepTimerDefaultAction;
    if (_userSelected ||
        !settings.isValidSleepTimerMinutes(loaded.sleepTimerDefaultMinutes)) {
      return;
    }
    _timer!.start(
      loaded.sleepTimerDefaultMinutes,
      action: loaded.sleepTimerDefaultAction,
    );
    _requestPermission(loaded.sleepTimerDefaultAction);
  }

  /// 只有会真正停播的行为才申请通知权限；`afterCurrent` 不发提醒。
  void _requestPermission(SleepTimerAction action) {
    final scope = _scope;
    if (scope != null) {
      scope.onTimerStarted(action);
      return;
    }
    if (_permissionRequested || action == SleepTimerAction.afterCurrent) {
      return;
    }
    _permissionRequested = true;
    unawaited(_notifier?.requestPermission());
  }

  @override
  void dispose() {
    _timer?.removeListener(_handleTimerChanged);
    _ownedTimer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = _timer!.isActive;
    final label = _timer!.pendingAfterCurrent
        ? (l10n?.afterCurrentItem ?? 'After current')
        : active
        ? _formatRemaining(_timer!.remaining!)
        : (l10n?.timer ?? 'Timer');
    final timerTitle = l10n?.sleepTimerTitle ?? 'Sleep timer';
    // `excludeSemantics: true` drops the InkWell's tap action, so the same
    // callback has to be declared on the Semantics node as well.
    void openPicker() {
      HapticFeedback.lightImpact();
      _userSelected = true;
      _showPicker(context);
    }

    return Tooltip(
      message: timerTitle,
      child: Semantics(
        button: true,
        label: '$timerTitle $label',
        onTap: openPicker,
        excludeSemantics: true,
        child: Material(
          color: active
              ? $styles.colors.accentFill.withValues(alpha: 0.9)
              : $styles.colors.scrim.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: openPicker,
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
                        minutes == _timer!.selectedMinutes &&
                        _timer!.action == _pendingAction,
                    onTap: () => _pick(sheetContext, minutes, _pendingAction),
                  ),
                _customOption(sheetContext),
                if (_timer!.isActive)
                  ListTile(
                    title: Text(
                      l10n?.cancelTimer ?? 'Cancel',
                      style: TextStyle(color: $styles.colors.accentText),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _userSelected = true;
                      _timer!.cancel();
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
    final selectedMinutes = _timer!.selectedMinutes;
    final selected =
        selectedMinutes != null &&
        !kSleepTimerMinutes.contains(selectedMinutes) &&
        _timer!.action == _pendingAction;
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
    _timer!.start(minutes, action: action);
    _requestPermission(action);
    Navigator.of(sheetContext).pop();
  }
}
