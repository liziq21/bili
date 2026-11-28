import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../../data/repository/danmaku_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import '../../../main.dart';
import '../player/media_playback_controller.dart';
import 'danmaku_painter.dart';
import 'danmaku_settings.dart';

class const DanmakuOverlay({
  super.key,
  required final MediaPlaybackController controller,
  required final String videoId,
}) extends StatefulWidget {
  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState() extends State<DanmakuOverlay> {
  StreamSubscription<PlaybackState>? _subscription;
  List<StreamSubscription>? _settingSubscriptions;
  Timer? _settingsReloadTimer;
  PlaybackState? _playbackState;
  DanmakuSettings _settings = const DanmakuSettings();
  List<DanmakuComment> _comments = const [];
  final DanmakuRenderCache _renderCache = DanmakuRenderCache();
  int _loadGeneration = 0;
  int _settingsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _playbackState = widget.controller.state;
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      // 浮层只消费位置；其他字段变化不会改变画面，跳过可省掉一次重建。
      if (_playbackState?.position == state.position) return;
      setState(() => _playbackState = state);
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    // Subscribe before the first read: a change made while it is in flight
    // must not be missed.
    _subscribeSettings(preferences);
    await _reloadSettings(preferences);
    if (!mounted || _loadGeneration != 0) return;
    await _loadComments();
  }

  /// 弹幕开关、字号等设置由设置页修改后立即生效，不必等切换视频。
  void _subscribeSettings(PreferencesDataSource preferences) {
    if (_settingSubscriptions != null) return;
    // `DanmakuSettings.save` writes all five keys, so one adjustment emits
    // five events. Coalesce them into a single snapshot read.
    void onChange(Object? _) => _scheduleSettingsReload();
    void onError(Object _, StackTrace _) {}
    _settingSubscriptions = [
      preferences
          .streamOf(PreferencesKey.danmakuEnabled)
          .listen(onChange, onError: onError),
      preferences
          .streamOf(PreferencesKey.danmakuRegularDuration)
          .listen(onChange, onError: onError),
      preferences
          .streamOf(PreferencesKey.danmakuOpacity)
          .listen(onChange, onError: onError),
      preferences
          .streamOf(PreferencesKey.danmakuFontSize)
          .listen(onChange, onError: onError),
      preferences
          .streamOf(PreferencesKey.danmakuOutlineRadius)
          .listen(onChange, onError: onError),
    ];
  }

  void _scheduleSettingsReload() {
    _settingsReloadTimer?.cancel();
    _settingsReloadTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      unawaited(_reloadSettings());
    });
  }

  Future<void> _reloadSettings([PreferencesDataSource? source]) async {
    final preferences = source ?? context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    final generation = ++_settingsGeneration;
    // A failed read keeps the value already on screen; the global defaults
    // would otherwise turn danmaku back on mid-playback.
    final settings = await DanmakuSettings.load(
      preferences,
      fallback: _settings,
    );
    if (!mounted || generation != _settingsGeneration) return;
    setState(() => _settings = settings);
  }

  Future<void> _loadComments() async {
    final generation = ++_loadGeneration;
    final repository = context.read<DanmakuRepository?>();
    if (repository == null) {
      if (mounted) setState(() => _comments = const []);
      return;
    }

    final result = await repository.getDanmaku(widget.videoId);
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _comments = switch (result) {
        Success(:final success) => List.unmodifiable(success),
        _ => const [],
      };
    });
  }

  @override
  void didUpdateWidget(covariant DanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId == widget.videoId) return;
    setState(() => _comments = const []);
    unawaited(_loadComments());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _settingSubscriptions?.forEach((subscription) => subscription.cancel());
    _settingsReloadTimer?.cancel();
    _renderCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.enabled || _comments.isEmpty) return const SizedBox.shrink();

    final state = _playbackState ?? widget.controller.state;
    final colors = (
      onScrim: $styles.colors.onScrim,
      outline: $styles.colors.outline,
    );
    return Positioned.fill(
      child: IgnorePointer(
        // 浮层铺满整个播放器方块，而画面按 contain 居中后可能带黑边；没有
        // 裁剪时滚动到画面外的文字会画在黑边上。安全边距同时让首行不被
        // 画面顶边裁切、进出场文字不在画面边缘被硬切。
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: $styles.insets.xs,
            vertical: $styles.insets.xxs,
          ),
          child: ClipRect(
            child: CustomPaint(
              painter: DanmakuPainter(
                comments: _comments,
                position: state.position,
                settings: _settings,
                colors: colors,
                cache: _renderCache,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
