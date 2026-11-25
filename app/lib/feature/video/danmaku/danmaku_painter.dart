import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

import 'danmaku_settings.dart';

/// 弹幕浮层颜色配置（从主题角色取值，不构造任意颜色）。
typedef DanmakuColors = ({Color onScrim, Color outline});

/// 同一轨道上两条弹幕之间的空档（秒），避免文字首尾相接看不出分界。
const double _laneGap = .25;

/// 画面最多容纳的滚动轨道数，避免一屏塞入过多弹幕。
const int _maxLanes = 8;

/// 文字排版缓存默认上限：同时可见的弹幕通常不到 40 条，200 条足以覆盖
/// 一段滚动窗口内的复用，又不会让缓存无限增长。
const int _defaultTextPainterCacheSize = 200;

/// 一条待绘制的弹幕及其轨道号。
typedef DanmakuSlot = ({DanmakuComment comment, int lane});

/// 一条已经确定轨道的弹幕。轨道只由开始时刻与更早弹幕的占用决定，
/// 与当前播放位置无关，因此整段时间线可以跨帧复用。
typedef DanmakuTimelineEntry = ({
  DanmakuComment comment,
  int lane,
  double start,
});

/// 文字排版缓存的键：内容与影响排版/描边的全部样式。
typedef _TextPainterKey = ({
  String content,
  double fontSize,
  double opacity,
  double outlineRadius,
  Color onScrim,
  Color outline,
  double maxWidth,
});

/// 给当前时间点仍在画面上的弹幕分配轨道，按开始时间升序返回。
///
/// 所有弹幕一律按滚动处理：来源里的顶/底/逆向标记只保留在数据层，不再影响
/// 排版。同一轨道的后一条必须等前一条让出画面才能进入，否则同一行会叠字。
/// 所有轨道都被占满时该条直接丢弃——少一条弹幕比叠字好读。
///
/// 轨道分配必须从第一条已开始的弹幕算起，不能只算当前可见窗口。一条弹幕的
/// 轨道取决于它开始时刻更早的弹幕是否还占着轨道；把已经滚出画面的前序弹幕
/// 从输入里剔掉，会让还在画面上的弹幕在下一帧换到别的轨道，看起来就是突然
/// 跳行。
///
/// 纯函数：只读输入，不碰 canvas，便于单测「同轨道不重叠」与「轨道不跳变」。
/// 需要跨帧复用时用 [DanmakuLayoutCache] 缓存 [DanmakuTimeline]。
List<DanmakuSlot> planDanmakuSlots({
  required Iterable<DanmakuComment> comments,
  required double positionSeconds,
  required Size size,
  required DanmakuSettings settings,
}) {
  if (size.isEmpty) return const [];
  return DanmakuTimeline.build(
    comments: comments is List<DanmakuComment>
        ? comments
        : comments.toList(growable: false),
    size: size,
    settings: settings,
  ).slotsAt(positionSeconds);
}

bool _isSortedByStart(List<DanmakuComment> comments) {
  for (var i = 1; i < comments.length; i++) {
    if (comments[i].startTime.compareTo(comments[i - 1].startTime) < 0) {
      return false;
    }
  }
  return true;
}

double _startSeconds(DanmakuComment comment) =>
    comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;

double _fontSizeOf(DanmakuComment comment, DanmakuSettings settings) =>
    (settings.fontSize * (comment.fontSize / 25)).clamp(
      settings.fontSize * .75,
      settings.fontSize * 1.4,
    );

/// 估算单行文字宽度：按最宽的中日韩全角字（1em/字）算。
///
/// 拉丁字母与数字实际更窄，估算只会偏大；偏大意味着轨道留得更松，不会让
/// 两条弹幕撞在一起。这里刻意不做 TextPainter 排版——已经滚出画面但仍占着
/// 轨道的弹幕也要参与估算。
double _estimatedWidth(String content, double fontSize) =>
    content.characters.length * fontSize;

/// 选一条可用轨道：先用弹幕自身指定的轨道，被占用时顺延。
///
/// 返回 null 表示所有轨道都还没空出来。
int? _claimLane(
  List<double> freeAt,
  int laneCount,
  DanmakuComment comment,
  double start,
) {
  final preferred =
      (comment.rowId ?? comment.content.hashCode).abs() % laneCount;
  for (var offset = 0; offset < laneCount; offset++) {
    final lane = (preferred + offset) % laneCount;
    if (freeAt[lane] <= start) return lane;
  }
  return null;
}

/// 预规划好的弹幕时间线。
///
/// 轨道规划必须从第一条已开始的弹幕算起（见 [planDanmakuSlots]），所以它
/// 天然是累积的：每条弹幕的轨道取决于更早的弹幕。把整段结果缓存下来后，
/// 重绘只按固定长度的可见窗口切片，不再每帧从时间轴起点重扫全量弹幕。
@immutable
final class const DanmakuTimeline(
  final List<DanmakuTimelineEntry> _entries,
  final double regularDuration,
) {
  factory build({
    required List<DanmakuComment> comments,
    required Size size,
    required DanmakuSettings settings,
  }) {
    if (size.isEmpty) {
      return DanmakuTimeline(const [], settings.regularDuration);
    }

    final lineHeight = settings.fontSize * 1.5;
    final laneCount = math.max(
      1,
      math.min(_maxLanes, (size.height / lineHeight).floor()),
    );

    var ordered = comments;
    if (!_isSortedByStart(comments)) {
      // Stable sort: equal start times keep their source order so that the
      // comments admitted to the limited lanes do not change when later,
      // out-of-order entries are added to the list.
      final order = List<int>.generate(comments.length, (index) => index)
        ..sort((a, b) {
          final byStart = comments[a].startTime.compareTo(
            comments[b].startTime,
          );
          return byStart != 0 ? byStart : a.compareTo(b);
        });
      ordered = [for (final index in order) comments[index]];
    }

    final freeAt = List<double>.filled(laneCount, double.negativeInfinity);
    final entries = <DanmakuTimelineEntry>[];
    for (final comment in ordered) {
      final start = _startSeconds(comment);
      final lane = _claimLane(freeAt, laneCount, comment, start);
      if (lane == null) continue;

      final width = _estimatedWidth(
        comment.content,
        _fontSizeOf(comment, settings),
      );
      // 滚动弹幕的尾巴越过右边缘后轨道就可以给下一条。
      freeAt[lane] =
          start +
          settings.regularDuration * width / (size.width + width) +
          _laneGap;
      entries.add((comment: comment, lane: lane, start: start));
    }
    return DanmakuTimeline(
      List<DanmakuTimelineEntry>.unmodifiable(entries),
      settings.regularDuration,
    );
  }

  /// 时间线里成功分到轨道的弹幕总数，包含已经滚出画面的那些。
  @visibleForTesting
  int get scheduledCount => _entries.length;

  /// 返回 [positionSeconds] 这一刻仍在滚动的弹幕。
  ///
  /// 所有弹幕的滚动时长都是 [regularDuration]，可见窗口长度因此固定；
  /// 用两次二分定位窗口，成本是 O(log n + 可见条数)。
  List<DanmakuSlot> slotsAt(double positionSeconds) {
    final first = _lowerBound(positionSeconds - regularDuration);
    final end = _upperBound(positionSeconds);
    if (first >= end) return const [];
    return [
      for (var i = first; i < end; i++)
        (comment: _entries[i].comment, lane: _entries[i].lane),
    ];
  }

  int _lowerBound(double value) {
    var low = 0;
    var high = _entries.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_entries[mid].start < value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  int _upperBound(double value) {
    var low = 0;
    var high = _entries.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_entries[mid].start <= value) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

/// 缓存 `(comments, size, settings)` 对应的轨道规划结果。
///
/// [comments] 必须是稳定实例：弹幕内容变化时要换一个新列表，缓存才会失效；
/// 原地修改同一个列表不会被发现。
final class DanmakuLayoutCache() {
  List<DanmakuComment>? _comments;
  Size? _size;
  DanmakuSettings? _settings;
  DanmakuTimeline? _timeline;
  int _builds = 0;

  @visibleForTesting
  int get buildCount => _builds;

  DanmakuTimeline timelineFor({
    required List<DanmakuComment> comments,
    required Size size,
    required DanmakuSettings settings,
  }) {
    final cached = _timeline;
    if (cached != null &&
        identical(comments, _comments) &&
        size == _size &&
        settings == _settings) {
      return cached;
    }

    final timeline = DanmakuTimeline.build(
      comments: comments,
      size: size,
      settings: settings,
    );
    _comments = comments;
    _size = size;
    _settings = settings;
    _timeline = timeline;
    _builds++;
    return timeline;
  }
}

/// 按文字内容与样式缓存已经排版好的 [TextPainter]。
///
/// 可见弹幕只有十几到几十条，但每帧都重新 `layout()` 仍会重复做字形排版
/// 与描边计算；命中缓存时可以直接 `paint`。超过 [maxEntries] 时淘汰最久
/// 未使用的一条并释放它。
final class DanmakuTextPainterCache({
  final int maxEntries = _defaultTextPainterCacheSize,
}) {
  final Map<_TextPainterKey, TextPainter> _painters = {};
  int _hits = 0;
  int _misses = 0;

  @visibleForTesting
  int get hitCount => _hits;

  @visibleForTesting
  int get missCount => _misses;

  @visibleForTesting
  int get length => _painters.length;

  int get _limit => math.max(1, maxEntries);

  TextPainter obtain({
    required String content,
    required double fontSize,
    required double opacity,
    required double outlineRadius,
    required Color onScrim,
    required Color outline,
    required double maxWidth,
  }) {
    final key = (
      content: content,
      fontSize: fontSize,
      opacity: opacity,
      outlineRadius: outlineRadius,
      onScrim: onScrim,
      outline: outline,
      maxWidth: maxWidth,
    );

    final cached = _painters.remove(key);
    if (cached != null) {
      _painters[key] = cached;
      _hits++;
      return cached;
    }

    _misses++;
    final painter = _layoutTextPainter(
      content: content,
      fontSize: fontSize,
      opacity: opacity,
      outlineRadius: outlineRadius,
      onScrim: onScrim,
      outline: outline,
      maxWidth: maxWidth,
    );
    _painters[key] = painter;
    if (_painters.length > _limit) {
      final oldest = _painters.keys.first;
      _painters.remove(oldest)?.dispose();
    }
    return painter;
  }

  void dispose() {
    for (final painter in _painters.values) {
      painter.dispose();
    }
    _painters.clear();
  }
}

/// 一次弹幕渲染会话共享的缓存。
///
/// 由浮层的 `State` 持有：`CustomPainter` 实例每次 build 都会重建，
/// 缓存不能放在 painter 内部。
final class DanmakuRenderCache({
  final int maxTextPainters = _defaultTextPainterCacheSize,
}) {
  this : textPainters = DanmakuTextPainterCache(maxEntries: maxTextPainters);

  final DanmakuLayoutCache layout = DanmakuLayoutCache();
  final DanmakuTextPainterCache textPainters;

  void dispose() => textPainters.dispose();
}

TextPainter _layoutTextPainter({
  required String content,
  required double fontSize,
  required double opacity,
  required double outlineRadius,
  required Color onScrim,
  required Color outline,
  required double maxWidth,
}) => TextPainter(
  text: TextSpan(
    text: content,
    style: TextStyle(
      color: onScrim.withValues(alpha: opacity),
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      shadows: [
        Shadow(
          color: outline.withValues(alpha: opacity),
          blurRadius: outlineRadius,
        ),
      ],
    ),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout(maxWidth: maxWidth);

/// 单条弹幕在画面上的落点。
///
/// 所有弹幕都从右向左穿过画面；`progress` 为 0 时在右边缘外，1 时在左边缘外。
@visibleForTesting
Offset danmakuTextOffset({
  required Size size,
  required double textWidth,
  required int lane,
  required double lineHeight,
  required double progress,
}) =>
    Offset(size.width - progress * (size.width + textWidth), lane * lineHeight);

/// 共享弹幕画家：视频弹幕浮层与直播弹幕浮层复用。
///
/// [position] 是当前时间轴位置（Duration），[comments] 中的每条弹幕
/// 以 [DanmakuComment.startTime] 标记其出现时刻。可见性窗口与轨道分配
/// 见 [planDanmakuSlots]。
///
/// [cache] 由调用方的 `State` 持有并跨帧传入；不传时每帧重新规划、
/// 重新排版，行为与旧实现一致，只是没有跨帧复用。
///
/// [comments] 必须是不可变快照：内容变化时换一个新列表。原地修改同一个
/// 列表不会被 `shouldRepaint` 或缓存发现，画面会停留在旧内容。
final class DanmakuPainter({
  required final List<DanmakuComment> comments,
  required final Duration position,
  required final DanmakuSettings settings,
  required final DanmakuColors colors,
  final DanmakuRenderCache? cache,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final currentSeconds =
        position.inMicroseconds / Duration.microsecondsPerSecond;
    final lineHeight = settings.fontSize * 1.5;
    final timeline =
        cache?.layout.timelineFor(
          comments: comments,
          size: size,
          settings: settings,
        ) ??
        DanmakuTimeline.build(
          comments: comments,
          size: size,
          settings: settings,
        );
    for (final slot in timeline.slotsAt(currentSeconds)) {
      _paintComment(
        canvas,
        size,
        slot.comment,
        lineHeight,
        slot.lane,
        _fontSizeOf(slot.comment, settings),
        currentSeconds,
      );
    }
  }

  void _paintComment(
    Canvas canvas,
    Size size,
    DanmakuComment comment,
    double lineHeight,
    int lane,
    double fontSize,
    double currentSeconds,
  ) {
    final textCache = cache?.textPainters;
    final painter =
        textCache?.obtain(
          content: comment.content,
          fontSize: fontSize,
          opacity: settings.opacity,
          outlineRadius: settings.outlineRadius,
          onScrim: colors.onScrim,
          outline: colors.outline,
          maxWidth: size.width * 1.5,
        ) ??
        _layoutTextPainter(
          content: comment.content,
          fontSize: fontSize,
          opacity: settings.opacity,
          outlineRadius: settings.outlineRadius,
          onScrim: colors.onScrim,
          outline: colors.outline,
          maxWidth: size.width * 1.5,
        );

    final elapsed = currentSeconds - _startSeconds(comment);
    final progress = (elapsed / settings.regularDuration).clamp(0.0, 1.0);
    final offset = danmakuTextOffset(
      size: size,
      textWidth: painter.width,
      lane: lane,
      lineHeight: lineHeight,
      progress: progress,
    );

    painter.paint(canvas, offset);
    if (textCache == null) painter.dispose();
  }

  @override
  bool shouldRepaint(DanmakuPainter oldDelegate) =>
      position != oldDelegate.position ||
      !identical(comments, oldDelegate.comments) ||
      settings != oldDelegate.settings ||
      colors != oldDelegate.colors ||
      cache != oldDelegate.cache;
}
