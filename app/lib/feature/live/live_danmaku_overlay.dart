import 'dart:async';

import 'package:clock/clock.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/repository/danmaku_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import '../../../main.dart';
import '../video/player/media_playback_controller.dart';
import '../video/danmaku/danmaku_painter.dart';
import '../video/danmaku/danmaku_settings.dart';

/// 直播弹幕浮层。
///
/// 订阅 [DanmakuRepository.liveDanmaku] 的实时弹幕流，以到达时刻为
/// 起点驱动共享 [DanmakuPainter] 渲染。弹幕参数通过
/// [PreferencesDataSource] 的广播流即时生效。
class const LiveDanmakuOverlay({
  super.key,
  required final MediaPlaybackController controller,
  required final int roomId,
}) extends StatefulWidget {
  @override
  State<LiveDanmakuOverlay> createState() => LiveDanmakuOverlayState();
}

/// 公开仅为了让测试断言 20 Hz 定时器的生命周期。
class LiveDanmakuOverlayState() extends State<LiveDanmakuOverlay> {
  /// 至少保留一个完整滚动窗口，防止配置的滚动时长超过 10 秒时，
  /// 仍在屏幕上的弹幕被提前裁掉。
  static const _minWindow = Duration(seconds: 10);

  static const _tickInterval = Duration(milliseconds: 50);

  Duration get _window {
    final seconds = _settings.regularDuration + 1;
    final configured = Duration(milliseconds: (seconds * 1000).ceil());
    return configured > _minWindow ? configured : _minWindow;
  }

  /// 早于该时刻的弹幕已经滚出保留窗口。
  Duration get _cutoff => _elapsed - _window;

  /// 从第一条弹幕开始算起的到达时长。
  Duration get _elapsed => clock.now().difference(_streamStart);

  /// 一条弹幕从开始到完全滚出画面所需的时长，与 `DanmakuTimeline` 一致。
  Duration get _scrollDuration =>
      Duration(microseconds: (_settings.regularDuration * 1e6).round());

  /// 画面上是否还有弹幕。
  ///
  /// `DanmakuTimeline.slotsAt` 只返回开始时刻落在
  /// `(position - regularDuration, position]` 的弹幕；列表按开始时刻升序，
  /// 最后一条就是最晚离场的，它一旦过期，整屏就空了。
  bool get _hasVisibleComment =>
      _comments.isNotEmpty &&
      _comments.last.startTime + _scrollDuration > _elapsed;

  List<DanmakuComment> _comments = const [];
  final DanmakuRenderCache _renderCache = DanmakuRenderCache();
  DanmakuSettings _settings = const DanmakuSettings();
  StreamSubscription<DanmakuComment>? _danmakuSubscription;
  List<StreamSubscription>? _settingSubscriptions;
  Timer? _ticker;
  int _settingsLoadId = 0;
  DateTime _streamStart = clock.now();

  @override
  void initState() {
    super.initState();
    _streamStart = clock.now();
    unawaited(_load());
  }

  Future<void> _load() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    final settings = await DanmakuSettings.load(preferences);
    if (!mounted) return;
    setState(() => _settings = settings);
    _subscribeSettings(preferences);
    _subscribeDanmaku();
  }

  void _subscribeSettings(PreferencesDataSource preferences) {
    _settingSubscriptions?.forEach((s) => s.cancel());
    _settingSubscriptions = [
      preferences
          .streamOf(PreferencesKey.danmakuEnabled)
          .listen((_) => _reloadSettings()),
      preferences
          .streamOf(PreferencesKey.danmakuRegularDuration)
          .listen((_) => _reloadSettings()),
      preferences
          .streamOf(PreferencesKey.danmakuOpacity)
          .listen((_) => _reloadSettings()),
      preferences
          .streamOf(PreferencesKey.danmakuFontSize)
          .listen((_) => _reloadSettings()),
      preferences
          .streamOf(PreferencesKey.danmakuOutlineRadius)
          .listen((_) => _reloadSettings()),
    ];
  }

  Future<void> _reloadSettings() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    // 多个偏好键各自触发重载，完成顺序不保证与发起顺序一致；只应用最后一次
    // 发起的结果，否则旧结果会把新设置覆盖回去。
    final loadId = ++_settingsLoadId;
    final settings = await DanmakuSettings.load(preferences);
    if (!mounted || loadId != _settingsLoadId) return;
    setState(() {
      _settings = settings;
      _pruneExpired();
    });
    _syncTicker();
  }

  void _subscribeDanmaku() {
    _danmakuSubscription?.cancel();
    final repository = context.read<DanmakuRepository?>();
    if (repository == null) return;
    _danmakuSubscription = repository.liveDanmaku(widget.roomId).listen((
      comment,
    ) {
      if (!mounted) return;
      final stamped = DanmakuComment(
        startTime: _nextStartTime(),
        mode: comment.mode,
        fontSize: comment.fontSize,
        colorArgb: comment.colorArgb,
        content: comment.content,
        rowId: comment.rowId,
      );
      setState(() {
        _pruneExpired();
        _comments = List.unmodifiable([..._comments, stamped]);
      });
      _syncTicker();
    });
  }

  /// 新弹幕的开始时刻。
  ///
  /// 系统时钟回拨会让到达时刻早于上一条，列表就不再按开始时刻升序，
  /// [_pruneExpired] 与 [_hasVisibleComment] 都依赖这个顺序；夹到上一条之后。
  Duration _nextStartTime() {
    final arrival = _elapsed;
    if (_comments.isEmpty || arrival > _comments.last.startTime) return arrival;
    return _comments.last.startTime;
  }

  /// 丢弃已经滚出保留窗口的弹幕。
  ///
  /// 只在收到新弹幕与设置变化时调用。定时器**不**做逐条裁剪：换掉列表实例会
  /// 让 `DanmakuLayoutCache` 从第一条弹幕重新排轨，仍在滚动中的弹幕少了前序
  /// 弹幕的轨道占用就会跳行。
  void _pruneExpired() {
    if (_comments.isEmpty) return;
    final cutoff = _cutoff;
    _comments = List.unmodifiable(
      _comments.where((comment) => comment.startTime >= cutoff),
    );
  }

  /// 定时器只在「弹幕开启且画面上还有弹幕」时存在。
  ///
  /// 关闭弹幕时 [build] 直接返回空 widget，此时重建没有任何可见效果。
  void _syncTicker() {
    if (!mounted || !_settings.enabled || !_hasVisibleComment) {
      _stopTicker();
      return;
    }
    _ticker ??= Timer.periodic(_tickInterval, (_) => _tick());
  }

  /// 有弹幕可见时只重绘，不动列表；一条都不剩时整体清空并停表。
  ///
  /// 清空发生在所有弹幕都已离屏之后，因此不会让任何可见弹幕重新排轨。
  void _tick() {
    if (!mounted) return;
    if (!_hasVisibleComment) {
      setState(() => _comments = const []);
      _stopTicker();
      return;
    }
    setState(() {});
  }

  /// 20 Hz 重绘定时器是否在跑。
  @visibleForTesting
  bool get isTickerRunning => _ticker != null;

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didUpdateWidget(covariant LiveDanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId == widget.roomId) return;
    // 换房间：旧订阅指向旧房间，必须断开；已到达的弹幕属于旧房间，
    // 不能混进新房间的浮层。build 紧跟 didUpdateWidget，直接赋值即可。
    _danmakuSubscription?.cancel();
    _danmakuSubscription = null;
    _stopTicker();
    _streamStart = clock.now();
    _comments = const [];
    _subscribeDanmaku();
  }

  @override
  void dispose() {
    _danmakuSubscription?.cancel();
    _settingSubscriptions?.forEach((s) => s.cancel());
    _stopTicker();
    _renderCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.enabled || !_hasVisibleComment) {
      return const SizedBox.shrink();
    }

    final position = _elapsed;
    final colors = (
      onScrim: $styles.colors.onScrim,
      outline: $styles.colors.outline,
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: DanmakuPainter(
            comments: _comments,
            position: position,
            settings: _settings,
            colors: colors,
            cache: _renderCache,
          ),
        ),
      ),
    );
  }
}
