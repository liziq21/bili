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
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final preferences = context.read<PreferencesDataSource?>();
    if (preferences == null) return;
    final repository = context.read<DanmakuRepository?>();
    final settings = await DanmakuSettings.load(preferences);
    if (generation != _loadGeneration) return;
    if (repository == null) {
      if (mounted) setState(() => _settings = settings);
      return;
    }

    final result = await repository.getDanmaku(widget.videoId);
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _settings = settings;
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
    unawaited(_load());
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
