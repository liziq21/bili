import 'dart:math' as math;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../l10n/compact_count.dart';
import '../l10n/localization_file/app_localizations.dart';
import '../main.dart';

enum VideoCardVariant() {
  defaultCard,
  feed,
}

class const VideoCard({
  super.key,
  required final VideoModel videoInfoBase,
  final GestureTapCallback? onTap,
  final VideoCardVariant variant = VideoCardVariant.defaultCard,
  final String? sourceBadge,
  final String? creatorAvatarUrl,
  final VoidCallback? onMorePressed,

  /// 标题最多显示几行。
  ///
  /// 默认两行。格子高度由 [videoCardExtent] 按两行算出来，只有调用方自己压
  /// 低了格子（例如固定高度更矮的网格）时才需要降到一行。
  final int titleMaxLines = 2,
}) extends StatelessWidget {
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String formatViewCount(int? count, [AppLocalizations? l10n]) {
    if (count == null) return '';
    if (l10n == null) return count < 10000 ? '$count' : '';
    return formatCompactCount(count, l10n);
  }

  static String formatRelativeDate(
    DateTime? dateTime, [
    AppLocalizations? l10n,
  ]) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      return l10n?.yearsAgoCompact((difference.inDays / 365).floor()) ?? '';
    } else if (difference.inDays >= 30) {
      return l10n?.monthsAgoCompact((difference.inDays / 30).floor()) ?? '';
    } else if (difference.inDays >= 1) {
      return l10n?.daysAgo(difference.inDays) ?? '';
    } else if (difference.inHours >= 1) {
      return l10n?.hoursAgo(difference.inHours) ?? '';
    } else if (difference.inMinutes >= 1) {
      return l10n?.minutesAgo(difference.inMinutes) ?? '';
    } else {
      return l10n?.justNow ?? '';
    }
  }

  Widget _thumbnailPlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Icon(AppIcons.movie, color: colorScheme.onSurfaceVariant),
  );

  Widget _thumbnail(ColorScheme colorScheme) =>
      switch (videoInfoBase.thumbnailUrl) {
        final String url when url.isNotEmpty => CachedNetworkImage(
          imageUrl: url,
          memCacheWidth: 480,
          fit: BoxFit.cover,
          errorBuilder: (context, url, error) =>
              _thumbnailPlaceholder(colorScheme),
        ),
        _ => _thumbnailPlaceholder(colorScheme),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (variant == VideoCardVariant.feed) {
      final formattedViews = formatViewCount(videoInfoBase.viewCount, l10n);
      final formattedDate = formatRelativeDate(videoInfoBase.uploadDate, l10n);
      final feedSubtitle = formattedViews.isNotEmpty
          ? (formattedDate.isNotEmpty
                ? l10n?.viewsWithDate(formattedViews, formattedDate) ?? ''
                : l10n?.viewsCount(formattedViews) ?? '')
          : (formattedDate.isNotEmpty
                ? formattedDate
                : (videoInfoBase.uploadDate != null
                      ? '${videoInfoBase.uploadDate}'
                      : ''));
      return _withMoreButton(l10n, _buildFeedCard(context, feedSubtitle));
    }

    final formattedViews = formatViewCount(videoInfoBase.viewCount, l10n);
    final formattedDate = formatRelativeDate(videoInfoBase.uploadDate, l10n);
    final creatorName = videoInfoBase.creatorProfileName;
    final durationStr = formatDuration(videoInfoBase.duration);

    final subtitleParts = <String>[
      if (creatorName != null && creatorName.isNotEmpty) creatorName,
      if (formattedViews.isNotEmpty) l10n?.viewsCount(formattedViews) ?? '',
      if (formattedDate.isNotEmpty) formattedDate,
    ];
    final subtitleText = subtitleParts.isNotEmpty
        ? subtitleParts.join(l10n?.spacedBullet ?? ' - ')
        : (videoInfoBase.uploadDate != null
              ? '${videoInfoBase.uploadDate}'
              : '');

    final semanticLabelParts = <String?>[
      videoInfoBase.title,
      if (creatorName != null && creatorName.isNotEmpty)
        l10n?.creatorLabel(creatorName),
      if (durationStr.isNotEmpty) l10n?.durationPrefix(durationStr),
      if (subtitleText.isNotEmpty) subtitleText,
    ];
    final semanticLabel = semanticLabelParts.whereType<String>().join(
      l10n?.commaSeparator ?? ',',
    );

    // `excludeSemantics: true` drops the InkWell's own semantics, so the tap
    // action has to be declared on the Semantics node too; otherwise the card
    // is announced as a button that TalkBack/VoiceOver cannot activate.
    final handleTap = onTap == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onTap!();
          };

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: videoInfoBase.title,
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          onTap: handleTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: handleTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图区域
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _thumbnail(Theme.of(context).colorScheme),
                      if (durationStr.isNotEmpty)
                        Positioned(
                          bottom: $styles.insets.xs,
                          right: $styles.insets.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: $styles.insets.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: $styles.colors.scrim.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(
                                $styles.corners.sm,
                              ),
                            ),
                            child: Text(
                              durationStr,
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: $styles.colors.onScrim,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 文字区域：用 Expanded 承接剩下的所有空间
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 网格给的高度由 [videoCardExtent] 按两行标题算出来，
                        // 正常不会挤到标题；Flexible 只是兜底，让极端字号下
                        // 缺的几像素由标题让出，而不是整列溢出被圆角裁掉。
                        Flexible(
                          child: Text(
                            videoInfoBase.title,
                            maxLines: titleMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (subtitleText.isNotEmpty)
                          Text(
                            subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: $styles.colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return _withMoreButton(l10n, card);
  }

  /// 更多操作按钮浮在封面右上角。放进信息行会把标题挤成两三个字（380 宽下
  /// 实测），浮层不占文字宽度；它留在卡片 `Semantics` 之外，读屏仍能单独聚焦。
  Widget _withMoreButton(AppLocalizations? l10n, Widget card) {
    if (onMorePressed == null) return card;
    final label = l10n?.moreOptions ?? 'More options';
    return Stack(
      children: [
        card,
        Positioned(
          top: $styles.insets.xs,
          right: $styles.insets.xs,
          child: Material(
            color: $styles.colors.scrim.withValues(alpha: 0.6),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              tooltip: label,
              icon: Icon(
                AppIcons.moreVert,
                semanticLabel: label,
                size: 18,
                color: $styles.colors.onScrim,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: onMorePressed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedCard(BuildContext context, String subtitleText) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final durationStr = formatDuration(videoInfoBase.duration);
    final creatorName =
        videoInfoBase.creatorProfileName ?? (l10n?.unknownCreator ?? 'Unknown');

    final semanticLabel = <String?>[
      if (sourceBadge != null && sourceBadge!.isNotEmpty) sourceBadge!,
      videoInfoBase.title,
      l10n?.creatorLabel(creatorName),
      if (durationStr.isNotEmpty) l10n?.durationPrefix(durationStr),
      if (subtitleText.isNotEmpty) subtitleText,
    ].whereType<String>().join(l10n?.commaSeparator ?? ',');

    // ⚡ Bolt Optimization: Replace nested Material + Container(decoration: BoxDecoration)
    // with a single Material using shape: RoundedRectangleBorder(...).
    // Eliminates redundant Container element node allocations and unifies surface background,
    // rounded corner clipping, and border stroke painting into a single native Material canvas pass.
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($styles.corners.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // `Material.shape` strokes the border along the outer edge of its child,
      // while the `Container(decoration: BoxDecoration(border:))` this replaced
      // reserved the border width before laying out its child. Without the inset
      // below, card content reaches the Material edge and the foreground border
      // paints over the outer pixels of the thumbnail.
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图及覆盖 Badge 区域
                ExcludeSemantics(
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _thumbnail(colorScheme),
                      ),
                      // 顶部来源/平台 Badge
                      if (sourceBadge != null && sourceBadge!.isNotEmpty)
                        Positioned(
                          top: $styles.insets.xs,
                          left: $styles.insets.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: $styles.insets.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(
                                $styles.corners.sm,
                              ),
                            ),
                            child: Text(
                              sourceBadge!,
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      // 右下角时长 Badge
                      if (durationStr.isNotEmpty)
                        Positioned(
                          bottom: $styles.insets.xs,
                          right: $styles.insets.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: $styles.insets.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: $styles.colors.scrim.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(
                                $styles.corners.sm,
                              ),
                            ),
                            child: Text(
                              durationStr,
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: $styles.colors.onScrim,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 信息与 Creator 元数据区域
                //
                // `Expanded` 让这段只拿到封面之外的剩余高度：封面按 16:9 先
                // 吃掉它需要的那部分，文字块再在剩余空间里排版。没有这层，
                // 文字块按自身高度参与主轴分配，任何字体度量或取整差异都会
                // 变成卡片底部的 RenderFlex overflow（#678）。
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all($styles.insets.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ExcludeSemantics(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Creator 头像
                                // ⚡ Bolt Optimization: Wrap provider with ResizeImage.resizeIfNeeded.
                                // Visual size is 36x36px (radius 18). Capping decode resolution to 128x128px
                                // prevents decoding uncompressed high-res avatar images into full GPU RAM,
                                // saving ~2MB-8MB RAM per video item and eliminating raster thread decode jank during feed scroll.
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primaryContainer,
                                  backgroundImage:
                                      (creatorAvatarUrl != null &&
                                          creatorAvatarUrl!.isNotEmpty)
                                      ? ResizeImage.resizeIfNeeded(
                                          128,
                                          128,
                                          CachedNetworkImageProvider(
                                            creatorAvatarUrl!,
                                          ),
                                        )
                                      : null,
                                  // 热门 / 排行榜 Feed 不返回头像地址，占位用统一的
                                  // 人像图标而不是名字首字：整屏字母圆看起来像头像
                                  // 全部加载失败，图标才是「这里没有头像」的样子
                                  // （#685）。作者名仍在卡片语义标签里。
                                  child:
                                      (creatorAvatarUrl == null ||
                                          creatorAvatarUrl!.isEmpty)
                                      ? Icon(
                                          AppIcons.avatarFallback,
                                          size: 20,
                                          color: colorScheme.onPrimaryContainer,
                                        )
                                      : null,
                                ),
                                SizedBox(width: $styles.insets.xs),

                                // 标题与次要信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // `Flexible` 让标题在高度不足时先让出行高，
                                      // 而不是把整列顶出格子（#678）。
                                      Flexible(
                                        child: Tooltip(
                                          message: videoInfoBase.title,
                                          child: Text(
                                            videoInfoBase.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: $styles.text.title2.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: $styles.insets.xxs),
                                      _MetadataLine(
                                        creatorName: creatorName,
                                        stats: subtitleText,
                                        separator: l10n?.spacedBullet ?? ' - ',
                                        style: $styles.text.bodySmall.copyWith(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 「作者 · 统计」单行元信息。
///
/// 作者名和播放量 / 日期拼成一个字符串再整串省略时，窄卡片上被截掉的总是
/// 末尾的统计数字，而那才是读者最需要的信息（#682）。这里先量出统计信息
/// 需要的宽度，把它按自身宽度排完，作者名只吃剩下的空间并先被省略。
///
/// 剩余空间连一个可读的作者名都放不下时（360 宽两列网格就是这种情况），
/// 只显示统计信息：作者名仍保留在卡片的语义标签里。
class const _MetadataLine({
  required final String creatorName,
  required final String stats,
  required final String separator,
  required final TextStyle style,
}) extends StatelessWidget {
  /// 作者名至少要有这么宽才值得显示，否则整行让给统计信息。
  ///
  /// 12px 字号下约等于 3 个 CJK 字：再窄的名字只剩下省略号，读者看不出
  /// 是谁，却挤掉了统计信息。
  static const double _minCreatorWidth = 40;

  @override
  Widget build(BuildContext context) {
    // 卡片里的 `Text` 会把自身样式合并到环境样式上，量测必须用同一份结果，
    // 否则继承来的字体或字距会让预留宽度偏小，统计信息被多省略一截。
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final single = stats.isEmpty
        ? creatorName
        : (creatorName.isEmpty ? stats : null);
    if (single != null) return _line(single, resolved);

    final scaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    // 阈值跟着系统字号放大，避免放大后仍按 40dp 判定「放得下」，结果只露出
    // 半个名字。
    final minCreatorWidth = scaler.scale(_minCreatorWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final statsWidth = _measureWidth(
          stats,
          resolved,
          scaler,
          textDirection,
        );
        final separatorWidth = _measureWidth(
          separator,
          resolved,
          scaler,
          textDirection,
        );
        final creatorSpace = constraints.maxWidth - statsWidth - separatorWidth;
        if (creatorSpace < minCreatorWidth) return _line(stats, resolved);
        return Row(
          children: [
            Expanded(child: _line(creatorName, resolved)),
            Text(separator, style: resolved, maxLines: 1),
            ConstrainedBox(
              // 统计信息按自身宽度排完，最多占满整行；`Expanded` 的作者名
              // 只拿剩下的宽度，两者之和不会超过行宽。
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: _line(stats, resolved),
            ),
          ],
        );
      },
    );
  }

  Widget _line(String text, TextStyle resolved) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: resolved);

  static double _measureWidth(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// 网格卡片在给定宽度下需要的高度。
///
/// 两个变体的文字高度都用 [TextPainter] 按卡片真实的 [TextStyle] 量出来，
/// 而不是用 `fontSize * height * 行数` 估算。估算会漏掉两件事：引擎把每行
/// 行高向上取整到整数逻辑像素；CJK 回退字体的自然 ascent+descent 可能超过
/// `fontSize * height`。任一遗漏都让预算比实际矮零点几到几像素，卡片底部的
/// `Column` 就会触发 `RenderFlex overflow`（#662）。
///
/// 量到的样式是「卡片里 [Text] 真正拿到的样式」：`Text` 会把自身样式合并到
/// `Material` 提供的 `DefaultTextStyle`（`theme.textTheme.bodyMedium`）上，
/// 只量裸 token 会漏掉继承来的行高与字体（#678）。
///
/// 封面高度按卡片内层宽度（扣掉 `Material` 内层的 1px 边框）计算，与
/// [VideoCard] 里 `AspectRatio` 实际拿到的约束一致；旧公式用卡片外宽，多算
/// 出的那一点恰好掩盖了文字预算的缺口，掩盖多少又随宽度变化，所以同一个
/// 偏差在某些宽度不溢出、某些宽度溢出。
///
/// 返回值末尾加 [_extentSlack]：不同引擎/字体下 [TextPainter] 的单行高度与
/// 最终排版仍可能差零点几像素，格子留一点余量，副标题才不会被卡片圆角裁掉。
/// 这只是余量，不是防溢出的主要手段——卡片内部用 `Flexible` 保证了文字块
/// 撑不破格子。
double videoCardExtent(
  BuildContext context,
  double cardWidth, {
  VideoCardVariant variant = VideoCardVariant.defaultCard,
  int titleMaxLines = 2,
}) {
  final textScaler = MediaQuery.textScalerOf(context);
  final innerWidth = cardWidth - _cardBorder * 2;
  final coverHeight = innerWidth * 9 / 16;
  // 卡片的 `Text` 继承 `Material` 的 `bodyMedium`（含行高 1.43）。按裸
  // `TextStyle(fontSize: 13)` 量会漏掉这个行高，每行少算约 4px，两行标题的
  // 第二行会被卡片圆角裁掉。
  final inherited = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

  final (double textHeight, double padding) = switch (variant) {
    VideoCardVariant.feed => (
      math.max(
        _lineHeight(
                  inherited.merge(
                    $styles.text.title2.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  textScaler,
                ) *
                titleMaxLines +
            $styles.insets.xxs +
            _lineHeight(
              inherited.merge($styles.text.bodySmall.copyWith(fontSize: 12)),
              textScaler,
            ),
        _feedAvatarDiameter,
      ),
      $styles.insets.sm,
    ),
    VideoCardVariant.defaultCard => (
      _lineHeight(
                inherited.merge(
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                textScaler,
              ) *
              titleMaxLines +
          _lineHeight(
            inherited.merge(const TextStyle(fontSize: 11)),
            textScaler,
          ),
      8.0,
    ),
  };

  return (coverHeight +
          _cardBorder * 2 +
          padding * 2 +
          textHeight +
          _extentSlack)
      .ceilToDouble();
}

/// 格子高度相对量测值的余量，吸收字体回退与子像素取整的差异。
const double _extentSlack = 2;

/// `Material` 内层 `Padding(EdgeInsets.all(1))` 的边框宽度。
const double _cardBorder = 1;

/// 信息区头像直径：`CircleAvatar(radius: 18)`。
const double _feedAvatarDiameter = 36;

/// 一行文字在真实字体下的高度。
///
/// 样本同时含拉丁与 CJK 字形：行高由该行实际用到的字体决定，只量 `M` 会漏掉
/// 更高的 CJK 回退字体。引擎会把行高向上取整，[TextPainter] 量到的就是最终
/// 渲染高度。
///
/// CJK 字符用码点构造，避免在源码里写非 ASCII 字面量（硬编码文案护栏）。
double _lineHeight(TextStyle style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: '${String.fromCharCode(0x4E2D)}M', style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}
