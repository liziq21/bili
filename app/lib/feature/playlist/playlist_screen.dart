import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../data/repository/playlist_content_repository.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../../ui/video_card.dart';

/// 远端播放列表详情页
///
/// 展示列表信息头、条目列表与分页，并提供「抓取全部」入口：点击后逐页拉取整个
/// 列表，进度以已抓取条目数展示到 [fetchFullPlaylist] 返回为止。
class const PlaylistScreen({
  super.key,
  final VoidCallback? onBackClick,
  required final String playlistId,
  final void Function(VideoModel video)? onVideoTap,
}) extends StatefulWidget {
  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState() extends State<PlaylistScreen> {
  PlaylistContentRepository? _repository;
  Future<Result<PlaylistDetail, Exception>>? _detailFuture;
  FullPlaylistFetchResult<VideoModel>? _fullResult;
  bool _isFetchingAll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<PlaylistContentRepository?>();
    if (_detailFuture != null && identical(repository, _repository)) return;

    _repository = repository;
    _detailFuture = _loadDetail();
  }

  @override
  void didUpdateWidget(covariant PlaylistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId == widget.playlistId) return;
    _fullResult = null;
    _detailFuture = _loadDetail();
  }

  Future<Result<PlaylistDetail, Exception>> _loadDetail() async {
    final repository = _repository;
    if (repository == null) {
      return Result.error(Exception('Playlist content source unavailable'));
    }
    final result = await repository.fetchPlaylistContent(
      playlistId: widget.playlistId,
    );
    return switch (result) {
      Success(:final success) => switch (success.data) {
        [final detail, ...] => Result.success(detail),
        <PlaylistDetail>[] => Result.error(
          Exception('Playlist ${widget.playlistId} has no content'),
        ),
      },
      Error(:final error) => Result.error(error),
    };
  }

  void _retry() {
    setState(() {
      _detailFuture = _loadDetail();
    });
  }

  Future<void> _fetchAll() async {
    final repository = _repository;
    if (repository == null || _isFetchingAll) return;
    setState(() {
      _isFetchingAll = true;
    });

    final result = await repository.fetchAll(playlistId: widget.playlistId);
    if (!mounted) return;
    setState(() {
      _isFetchingAll = false;
      _fullResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the route subtree subscribed to brightness changes because `$styles`
    // is a mutable singleton refreshed by AppScaffold.
    Theme.of(context);
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackClick == null
            ? null
            : IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onBackClick?.call();
                },
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(l10n.playlistTitle),
      ),
      body: FutureBuilder<Result<PlaylistDetail, Exception>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: $styles.colors.accentFill,
              ),
            );
          }

          return switch (snapshot.data) {
            Success(:final success) => _buildContent(context, success, l10n),
            Error() || null => _PlaylistLoadError(onRetry: _retry),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PlaylistDetail detail,
    AppLocalizations l10n,
  ) {
    final fullResult = _fullResult;
    final useFullItems = fullResult != null && fullResult.items.isNotEmpty;
    final items = useFullItems ? fullResult.items : detail.items;

    final spacing = $styles.insets.sm;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(spacing),
          sliver: SliverToBoxAdapter(
            child: _PlaylistHeader(
              detail: detail,
              isFetchingAll: _isFetchingAll,
              fetchedCount: useFullItems ? fullResult.items.length : null,
              completed: fullResult?.completed,
              onFetchAll: _fetchAll,
            ),
          ),
        ),
        if (items.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.playlistEmpty,
                style: $styles.text.body.copyWith(
                  color: $styles.colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            sliver: SliverGrid.builder(
              // 卡片高度按 16:9 封面再加两行标题与一行副标题推算，不写死像素：
              // 写死高度在窄屏上会让 [VideoCard] 的垂直 Column 溢出。
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 200,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final video = items[index];
                return VideoCard(
                  videoInfoBase: video,
                  onTap: widget.onVideoTap == null
                      ? null
                      : () => widget.onVideoTap!(video),
                );
              },
            ),
          ),
        SliverPadding(padding: EdgeInsets.only(bottom: spacing)),
      ],
    );
  }
}

class const _PlaylistHeader({
  required final PlaylistDetail detail,
  required final bool isFetchingAll,
  required final int? fetchedCount,
  required final bool? completed,
  required final VoidCallback onFetchAll,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final colorScheme = Theme.of(context).colorScheme;
    final description = detail.description?.trim();
    final shownCount = fetchedCount ?? detail.items.length;

    final progressText = switch ((isFetchingAll, fetchedCount, completed)) {
      (true, _, _) => l10n.playlistFetchAllProgress('$shownCount'),
      (false, final count?, true) => l10n.playlistFetchAllDone('$count'),
      (false, final count?, _) => l10n.playlistFetchAllPartial('$count'),
      (false, null, _) => null,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all($styles.insets.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail.coverUrl case final cover? when cover.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular($styles.corners.sm),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.playlist_play_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: $styles.insets.sm),
            Text(
              detail.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.h3.copyWith(
                color: $styles.colors.onSurfaceStrong,
              ),
            ),
            SizedBox(height: $styles.insets.xxs),
            Text(
              [
                if (detail.creatorName case final creator?)
                  l10n.creatorLabel(creator),
                if (detail.totalCount case final total?)
                  l10n.playlistItemCount('$total'),
              ].join(l10n.commaSeparator),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.sm),
            Text(
              description != null && description.isNotEmpty
                  ? description
                  : l10n.playlistDescriptionUnavailable,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurface,
                height: 1.4,
              ),
            ),
            SizedBox(height: $styles.insets.sm),
            Wrap(
              spacing: $styles.insets.sm,
              runSpacing: $styles.insets.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: isFetchingAll ? null : onFetchAll,
                  icon: isFetchingAll
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: $styles.colors.onAccentFill,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(l10n.playlistFetchAll),
                ),
                if (progressText != null)
                  Text(
                    progressText,
                    style: $styles.text.bodySmallBold.copyWith(
                      color: $styles.colors.accentText,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _PlaylistLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Padding(
        padding: EdgeInsets.all($styles.insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: $styles.colors.outline),
            SizedBox(height: $styles.insets.xs),
            Text(
              l10n.loadFailedRetryLater,
              textAlign: TextAlign.center,
              style: $styles.text.body.copyWith(
                color: $styles.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.xs),
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onRetry();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
