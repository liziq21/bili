import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../data/repository/creator_profile_repository.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';

class const SpaceScreen({
  super.key,
  final VoidCallback? onBackClick,
  required final String mid,
}) extends StatefulWidget {
  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState() extends State<SpaceScreen> {
  CreatorProfileRepository? _repository;
  Future<Result<CreatorProfile>>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<CreatorProfileRepository?>();
    if (_profileFuture != null && identical(repository, _repository)) return;

    _repository = repository;
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant SpaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mid == widget.mid) return;
    _profileFuture = _loadProfile();
  }

  Future<Result<CreatorProfile>> _loadProfile() {
    final repository = _repository;
    if (repository == null) {
      return Future.value(
        Result.error(Exception('Creator profile source unavailable')),
      );
    }
    return repository.getProfile(widget.mid);
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the route subtree subscribed to brightness changes because `$styles`
    // is a mutable singleton refreshed by AppScaffold.
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackClick == null
            ? null
            : IconButton(
                onPressed: widget.onBackClick,
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(l10n.creatorTab),
      ),
      body: FutureBuilder<Result<CreatorProfile>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: $styles.colors.accentFill,
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _ProfileLoadError(onRetry: _retry);
          }

          return switch (snapshot.data!) {
            Ok(:final value) => _CreatorProfileHeader(
              profile: value,
              colorScheme: colorScheme,
            ),
            Error() => _ProfileLoadError(onRetry: _retry),
          };
        },
      ),
    );
  }
}

class const _ProfileLoadError({required final VoidCallback onRetry})
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
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class const _CreatorProfileHeader({
  required final CreatorProfile profile,
  required final ColorScheme colorScheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final description = profile.description?.trim();
    final stats = <String>[
      if (profile.subscribers case final subscribers?)
        l10n.subscribersCount(_formatCount(subscribers, l10n)),
      if (profile.videos case final videos?)
        l10n.videosCount(_formatCount(videos, l10n)),
      if (profile.isLive == true) l10n.liveNow,
    ];

    return ListView(
      padding: EdgeInsets.all($styles.insets.sm),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all($styles.insets.sm),
            child: Semantics(
              container: true,
              label: [
                profile.name,
                l10n.creatorLabel('@${profile.id}'),
                if (description != null && description.isNotEmpty) description,
                ...stats,
              ].join(l10n.commaSeparator),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CreatorAvatar(
                        profile: profile,
                        colorScheme: colorScheme,
                      ),
                      SizedBox(width: $styles.insets.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: $styles.text.h3.copyWith(
                                color: $styles.colors.onSurfaceStrong,
                              ),
                            ),
                            SizedBox(height: $styles.insets.xxs),
                            Text(
                              l10n.creatorLabel('@${profile.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: $styles.text.bodySmall.copyWith(
                                color: $styles.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: $styles.insets.sm),
                  Text(
                    description != null && description.isNotEmpty
                        ? description
                        : l10n.spaceDescriptionUnavailable,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: $styles.text.bodySmall.copyWith(
                      color: $styles.colors.onSurface,
                      height: 1.4,
                    ),
                  ),
                  if (stats.isNotEmpty) ...[
                    SizedBox(height: $styles.insets.sm),
                    Wrap(
                      spacing: $styles.insets.sm,
                      runSpacing: $styles.insets.xxs,
                      children: [
                        for (final stat in stats)
                          Text(
                            stat,
                            style: $styles.text.bodySmallBold.copyWith(
                              color: $styles.colors.accentText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class const _CreatorAvatar({
  required final CreatorProfile profile,
  required final ColorScheme colorScheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = profile.thumbnailUrl;
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 40,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: hasThumbnail
          ? ResizeImage.resizeIfNeeded(
              160,
              160,
              CachedNetworkImageProvider(thumbnailUrl),
            )
          : null,
      child: hasThumbnail
          ? null
          : Text(
              initial,
              style: $styles.text.h3.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}

String _formatCount(int count, AppLocalizations l10n) {
  if (count >= 100000000) {
    return l10n.countCompactYi((count / 100000000).toStringAsFixed(1));
  }
  if (count >= 10000) {
    return l10n.countCompactWan((count / 10000).toStringAsFixed(1));
  }
  return '$count';
}
