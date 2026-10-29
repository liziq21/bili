import 'dart:async';
import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../../data/repository/danmaku_repository.dart';
import '../../../datastore/preferences_data_source.dart';
import '../../../main.dart';
import '../player/media_playback_controller.dart';
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
          painter: _DanmakuPainter(
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

typedef _DanmakuColors = ({
  Color onScrim,
  Color accentText,
  Color secondary,
  Color tertiary,
  Color outline,
});

final class _DanmakuPainter({
  required final List<DanmakuComment> comments,
  required final Duration position,
  required final DanmakuSettings settings,
  required final _DanmakuColors colors,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final currentSeconds =
        position.inMicroseconds / Duration.microsecondsPerSecond;
    final lineHeight = settings.fontSize * 1.5;
    final normalRows = math.max(
      1,
      math.min(8, (size.height / lineHeight).floor()),
    );
    final visible = comments.where((comment) {
      final duration = _durationOf(comment);
      final elapsed =
          currentSeconds -
          comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;
      return elapsed >= 0 && elapsed <= duration;
    });

    for (final comment in visible) {
      _paintComment(
        canvas,
        size,
        comment,
        lineHeight,
        normalRows,
        currentSeconds,
      );
    }
  }

  void _paintComment(
    Canvas canvas,
    Size size,
    DanmakuComment comment,
    double lineHeight,
    int normalRows,
    double currentSeconds,
  ) {
    final fontSize = (settings.fontSize * (comment.fontSize / 25)).clamp(
      settings.fontSize * .75,
      settings.fontSize * 1.4,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: comment.content,
        style: TextStyle(
          color: _colorFor(comment).withValues(alpha: settings.opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: colors.outline.withValues(alpha: settings.opacity),
              blurRadius: settings.outlineRadius,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width * 1.5);

    final elapsed =
        currentSeconds -
        comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;
    final duration = _durationOf(comment);
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final rowId = comment.rowId ?? comment.content.hashCode;
    final row = rowId.abs();
    final Offset offset;
    switch (comment.mode) {
      case DanmakuMode.top:
        final topRows = math.max(1, settings.topMaxRows);
        offset = Offset(
          (size.width - painter.width) / 2,
          (row % topRows) * lineHeight,
        );
      case DanmakuMode.bottom:
        final bottomRows = math.max(1, settings.bottomMaxRows);
        offset = Offset(
          (size.width - painter.width) / 2,
          size.height - (row % bottomRows + 1) * lineHeight,
        );
      case DanmakuMode.reverse:
        offset = Offset(
          progress * (size.width + painter.width) - painter.width,
          (row % normalRows) * lineHeight,
        );
      case DanmakuMode.scrolling || DanmakuMode.special:
        offset = Offset(
          size.width - progress * (size.width + painter.width),
          (row % normalRows) * lineHeight,
        );
    }

    painter.paint(canvas, offset);
  }

  double _durationOf(DanmakuComment comment) {
    return switch (comment.mode) {
      DanmakuMode.top || DanmakuMode.bottom => settings.topBottomDuration,
      _ => settings.regularDuration,
    };
  }

  Color _colorFor(DanmakuComment comment) {
    // Content colors are quantized to the active theme roles rather than
    // constructing arbitrary colors in app/lib. This keeps the overlay
    // readable with DynamicColor while retaining light/dark and warm/cool
    // intent from the source XML.
    final rgb = comment.colorArgb & 0x00FFFFFF;
    final red = (rgb >> 16) & 0xFF;
    final green = (rgb >> 8) & 0xFF;
    final blue = rgb & 0xFF;
    final luminance = (red * .2126 + green * .7152 + blue * .0722) / 255;
    if (luminance >= .78) return colors.onScrim;
    if (red >= green && red >= blue) return colors.tertiary;
    if (green >= blue) return colors.secondary;
    return colors.accentText;
  }

  @override
  bool shouldRepaint(_DanmakuPainter oldDelegate) => true;
}
