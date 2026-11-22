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
  PlaybackState? _playbackState;
  DanmakuSettings _settings = const DanmakuSettings();
  List<DanmakuComment> _comments = const [];
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _playbackState = widget.controller.state;
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _playbackState = state);
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    await _reloadSettings(preferences);
    if (!mounted) return;
    _subscribeSettings(preferences);
    await _loadComments();
  }

  /// 弹幕开关、字号等设置由设置页修改后立即生效，不必等切换视频。
  void _subscribeSettings(PreferencesDataSource preferences) {
    if (_settingSubscriptions != null) return;
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

  Future<void> _reloadSettings([PreferencesDataSource? source]) async {
    final preferences = source ?? context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    final settings = await DanmakuSettings.load(preferences);
    if (!mounted) return;
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
        Success(:final success) => success,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.enabled || _comments.isEmpty) return const SizedBox.shrink();

    final state = _playbackState ?? widget.controller.state;
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
            position: state.position,
            settings: _settings,
            colors: colors,
          ),
        ),
      ),
    );
  }
}
