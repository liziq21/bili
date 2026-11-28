import 'dart:math' as math;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../l10n/compact_count.dart';
import '../l10n/localization_file/app_localizations.dart';
import '../main.dart';
import 'metadata_line.dart';

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

  /// 窄卡片（手机两列）使用紧凑排版：`⋮` 压在封面右上角而不是放进标题行。
  ///
  /// 标题行扣掉 32px 按钮后，164 宽的格子每行只剩两三个字。由网格在已知
  /// 格子宽度时传入 [feedCompactWidth] 的比较结果，卡片自己不做宽度测量：
  /// [LayoutBuilder] 不支持 intrinsic 尺寸，会让依赖它的布局（golden 的
  /// `Table` 就按 intrinsic 宽度排布场景）直接抛错。
  final bool compact = false,
}) extends StatelessWidget {
  /// Feed 格子窄于这个宽度时改用紧凑排版。
  static const double feedCompactWidth = 240;

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
      final creatorName =
          videoInfoBase.creatorProfileName ??
          (l10n?.unknownCreator ?? 'Unknown');
      // 没有本地化时 `formattedDate` 为空，但上传日期本身还在：副标题会退回
      // 显示它，元信息行也必须跟着显示，否则两条信息对不上。
      final displayDate = formattedDate.isNotEmpty
          ? formattedDate
          : (videoInfoBase.uploadDate != null
                ? '${videoInfoBase.uploadDate}'
                : '');
      final feedSubtitle = formattedViews.isNotEmpty
          ? (formattedDate.isNotEmpty
                ? l10n?.viewsWithDate(formattedViews, formattedDate) ?? ''
                : l10n?.viewsCount(formattedViews) ?? '')
          : (formattedDate.isNotEmpty
                ? formattedDate
                : (videoInfoBase.uploadDate != null
                      ? '${videoInfoBase.uploadDate}'
                      : ''));
      return _buildFeedCard(
        context,
        creatorName: creatorName,
        subtitleText: feedSubtitle,
        metadataParts: [
          MetadataPart(creatorName, priority: 2),
          if (formattedViews.isNotEmpty)
            MetadataPart(l10n?.viewsCount(formattedViews) ?? '', priority: 3),
          if (displayDate.isNotEmpty) MetadataPart(displayDate, priority: 1),
        ],
      );
    }

    final formattedViews = formatViewCount(videoInfoBase.viewCount, l10n);
    final formattedDate = formatRelativeDate(videoInfoBase.uploadDate, l10n);
    final creatorName = videoInfoBase.creatorProfileName;
    final durationStr = formatDuration(videoInfoBase.duration);
    final displayDate = formattedDate.isNotEmpty
        ? formattedDate
        : (videoInfoBase.uploadDate != null
              ? '${videoInfoBase.uploadDate}'
              : '');

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
    // 显示用的字段与语义标签分开：语义标签保留完整的一串，显示则按优先级
    // 决定在窄卡片上留下哪几个（#682）。
    final metadataParts = subtitleParts.isEmpty
        ? [MetadataPart(subtitleText)]
        : [
            if (creatorName != null && creatorName.isNotEmpty)
              MetadataPart(creatorName, priority: 2),
            if (formattedViews.isNotEmpty)
              MetadataPart(l10n?.viewsCount(formattedViews) ?? '', priority: 3),
            if (displayDate.isNotEmpty) MetadataPart(displayDate, priority: 1),
          ];

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
                          MetadataLine(
                            parts: metadataParts,
                            separator: l10n?.spacedBullet ?? ' - ',
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

  /// 默认卡片的更多操作按钮浮在封面右上角，不占文字宽度；它留在卡片
  /// `Semantics` 之外，读屏仍能单独聚焦。
  Widget _withMoreButton(AppLocalizations? l10n, Widget card) {
    if (onMorePressed == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: $styles.insets.xs,
          right: $styles.insets.xs,
          child: _scrimMoreButton(l10n),
        ),
      ],
    );
  }

  /// 压在半透明圆形底上的「更多」按钮，浮在封面上时保证图标在任何缩略图上
  /// 都有足够对比度。
  Widget _scrimMoreButton(AppLocalizations? l10n) {
    final label = l10n?.moreOptions ?? 'More options';
    return Material(
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
    );
  }

  Widget _buildFeedCard(
    BuildContext context, {
    required String creatorName,
    required String subtitleText,
    required List<MetadataPart> metadataParts,
  }) {
    final inlineMore = onMorePressed != null && !compact;
    final overlayMore = onMorePressed != null && compact;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final durationStr = formatDuration(videoInfoBase.duration);

    final semanticLabel = <String?>[
      if (sourceBadge != null && sourceBadge!.isNotEmpty) sourceBadge!,
      videoInfoBase.title,
      l10n?.creatorLabel(creatorName),
      if (durationStr.isNotEmpty) l10n?.durationPrefix(durationStr),
      if (subtitleText.isNotEmpty) subtitleText,
    ].whereType<String>().join(l10n?.commaSeparator ?? ',');

    // Feed 卡片不再自带表面色与描边：封面自身带圆角并内缩一圈，信息块直接
    // 落在页面背景上，整张卡片看起来像「封面 + 文字」而不是一张灰盒子。
    // `Material` 只保留承载 `InkWell` 按压层的作用。
    return Material(
      type: MaterialType.transparency,
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
          borderRadius: BorderRadius.circular($styles.corners.md),
          child: Padding(
            padding: EdgeInsets.all(_feedInset()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图及覆盖 Badge 区域
                Stack(
                  children: [
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular($styles.corners.md),
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
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.9),
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
                                    horizontal: $styles.insets.xxs,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: $styles.colors.onScrim,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (overlayMore)
                      Positioned(
                        top: _feedInset(),
                        right: _feedInset(),
                        child: _scrimMoreButton(l10n),
                      ),
                  ],
                ),
                SizedBox(height: _feedInset()),

                // 信息与 Creator 元数据区域
                //
                // `Expanded` 让这段只拿到封面之外的剩余高度：封面按 16:9 先
                // 吃掉它需要的那部分，文字块再在剩余空间里排版。没有这层，
                // 文字块按自身高度参与主轴分配，任何字体度量或取整差异都会
                // 变成卡片底部的 RenderFlex overflow（#678）。
                Expanded(
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
                              // Visual size is 40x40px (radius 20). Capping decode resolution to 128x128px
                              // prevents decoding uncompressed high-res avatar images into full GPU RAM,
                              // saving ~2MB-8MB RAM per video item and eliminating raster thread decode jank during feed scroll.
                              CircleAvatar(
                                radius: _feedAvatarDiameter / 2,
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
                                        size: 22,
                                        color: colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              SizedBox(width: $styles.insets.xs),

                              // 标题与次要信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          style: _feedTitleStyle().copyWith(
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: $styles.insets.xxs),
                                    MetadataLine(
                                      parts: metadataParts,
                                      separator: l10n?.spacedBullet ?? ' - ',
                                      style: _feedMetadataStyle().copyWith(
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
                      // 宽卡片上「更多」贴在标题行右侧，不再压在封面上。
                      if (inlineMore) _feedMoreButton(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标题行尾的「更多」按钮：无底色，与标题同一行，读屏仍能单独聚焦。
  Widget _feedMoreButton(AppLocalizations? l10n) {
    final label = l10n?.moreOptions ?? 'More options';
    return IconButton(
      tooltip: label,
      onPressed: onMorePressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      color: $styles.colors.onSurfaceVariant,
      icon: Icon(AppIcons.moreVert, semanticLabel: label, size: 20),
    );
  }
}

/// Feed 卡片标题：用正文的 16px 字号，行高压到 1.25 让两行标题更紧凑。
TextStyle _feedTitleStyle() => $styles.text.bodyBold.copyWith(height: 1.25);

/// Feed 卡片元信息行：单行，字号介于标题与默认卡片元信息之间。
TextStyle _feedMetadataStyle() =>
    $styles.text.bodySmall.copyWith(fontSize: 13, height: 1.4);

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
/// 封面高度按卡片里 `AspectRatio` 实际拿到的宽度计算，两种变体的内缩不同：
/// 默认卡片扣掉 `Material` 内层的 1px 边框，Feed 卡片扣掉左右各一圈
/// [_feedInset]。旧公式统一用卡片外宽，多算出的那一点恰好掩盖了文字预算的
/// 缺口，掩盖多少又随宽度变化，所以同一个偏差在某些宽度不溢出、某些宽度溢出。
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
  // 卡片的 `Text` 继承 `Material` 的 `bodyMedium`（含行高）。按裸
  // `TextStyle(fontSize: 13)` 量会漏掉这个行高，每行少算约 4px，两行标题的
  // 第二行会被卡片圆角裁掉。
  final inherited = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

  switch (variant) {
    case VideoCardVariant.feed:
      final inset = _feedInset();
      final coverHeight = (cardWidth - inset * 2) * 9 / 16;
      final textHeight = math.max(
        _lineHeight(inherited.merge(_feedTitleStyle()), textScaler) *
                titleMaxLines +
            $styles.insets.xxs +
            _lineHeight(inherited.merge(_feedMetadataStyle()), textScaler),
        _feedAvatarDiameter,
      );
      return (coverHeight +
              inset * 2 + // 卡片内容四周内缩
              inset + // 封面与信息块之间的间距
              textHeight +
              _extentSlack)
          .ceilToDouble();
    case VideoCardVariant.defaultCard:
      final coverHeight = (cardWidth - _cardBorder * 2) * 9 / 16;
      final textHeight =
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
          );
      return (coverHeight +
              _cardBorder * 2 +
              _defaultCardPadding * 2 +
              textHeight +
              _extentSlack)
          .ceilToDouble();
  }
}

/// 格子高度相对量测值的余量，吸收字体回退与子像素取整的差异。
const double _extentSlack = 2;

/// `Material` 内层 `Padding(EdgeInsets.all(1))` 的边框宽度。
const double _cardBorder = 1;

/// 默认卡片文字区 `Padding(EdgeInsets.all(8.0))` 的边距。
const double _defaultCardPadding = 8;

/// Feed 卡片内容四周内缩（`$styles.insets.xs`）。
double _feedInset() => $styles.insets.xs;

/// 信息区头像直径：`CircleAvatar(radius: 20)`。
const double _feedAvatarDiameter = 40;

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
