import 'dart:async';

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
  State<LiveDanmakuOverlay> createState() => _LiveDanmakuOverlayState();
}

class _LiveDanmakuOverlayState extends State<LiveDanmakuOverlay> {
  /// 滚动窗口：超过 10 秒的弹幕不再保留，防止内存增长。
  static const _maxWindow = Duration(seconds: 10);

  List<DanmakuComment> _comments = const [];
  DanmakuSettings _settings = const DanmakuSettings();
  StreamSubscription<DanmakuComment>? _danmakuSubscription;
  List<StreamSubscription>? _settingSubscriptions;
  Timer? _ticker;
  DateTime _streamStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _streamStart = DateTime.now();
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
          .streamOf(PreferencesKey.danmakuTopBottomDuration)
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
      preferences
          .streamOf(PreferencesKey.danmakuTopMaxRows)
          .listen((_) => _reloadSettings()),
      preferences
          .streamOf(PreferencesKey.danmakuBottomMaxRows)
          .listen((_) => _reloadSettings()),
    ];
  }

  Future<void> _reloadSettings() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    final settings = await DanmakuSettings.load(preferences);
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  void _subscribeDanmaku() {
    _danmakuSubscription?.cancel();
    final repository = context.read<DanmakuRepository?>();
    if (repository == null) return;
    _danmakuSubscription = repository.liveDanmaku(widget.roomId).listen((
      comment,
    ) {
      if (!mounted) return;
      final arrival = DateTime.now().difference(_streamStart);
      final stamped = DanmakuComment(
        startTime: arrival,
        mode: comment.mode,
        fontSize: comment.fontSize,
        colorArgb: comment.colorArgb,
        content: comment.content,
        rowId: comment.rowId,
      );
      setState(() {
        _comments = [..._comments, stamped];
        final cutoff = DateTime.now().difference(_streamStart) - _maxWindow;
        _comments = _comments.where((c) => c.startTime >= cutoff).toList();
      });
      _ensureTicker();
    });
  }

  void _ensureTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {});
      if (_comments.isEmpty) _stopTicker();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _danmakuSubscription?.cancel();
    _settingSubscriptions?.forEach((s) => s.cancel());
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.enabled || _comments.isEmpty) return const SizedBox.shrink();

    final position = DateTime.now().difference(_streamStart);
    final colors = (
      onScrim: $styles.colors.onScrim,
      accentText: $styles.colors.accentText,
      secondary: $styles.colors.secondary,
      tertiary: $styles.colors.tertiary,
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
          ),
        ),
      ),
    );
  }
}
