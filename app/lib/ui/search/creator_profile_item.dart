import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/compact_count.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../creator_subscribe_button.dart';

class const CreatorProfileItem({
  super.key,
  required final CreatorProfile creatorProfile,
  final Function()? onTap,
  final bool? isSubscribed,
  final VoidCallback? onToggleSubscribe,
}) extends StatelessWidget {
  static String formatCount(int? count, [AppLocalizations? l10n]) {
    if (count == null || l10n == null) return '';
    return formatCompactCount(count, l10n);
  }

  @override
  Widget build(BuildContext context) {
    // `$styles.colors.*` below is read from a mutable static that `AppScaffold`
    // refreshes during its own build. Reading a global in `build()` registers no
    // InheritedWidget dependency, so nothing tells Flutter to rebuild this item
    // when the brightness flips: `AppScaffold` does rebuild (it reads
    // `Theme.of`), but it hands back the same child widget instance and
    // `Element.updateChild` short-circuits on an identical child, leaving the
    // whole route subtree on the previous palette. The dependency read is the
    // cheap opt-in — see `feature/video/video_screen.dart` for the long form.
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);
    final formattedSubscribers = formatCount(creatorProfile.subscribers, l10n);
    final formattedVideos = formatCount(creatorProfile.videos, l10n);

    final statsParts = <String>[
      '@${creatorProfile.id}',
      if (formattedSubscribers.isNotEmpty)
        l10n?.subscribersCount(formattedSubscribers) ?? '',
      if (formattedVideos.isNotEmpty) l10n?.videosCount(formattedVideos) ?? '',
      if (creatorProfile.isLive == true) l10n?.liveNow ?? '',
    ];
    final subtitleText = statsParts.whereType<String>().join(
      l10n?.spacedBullet ?? ' - ',
    );

    final semanticStatsParts = <String?>[
      if (formattedSubscribers.isNotEmpty)
        l10n?.subscribersCount(formattedSubscribers),
      if (formattedVideos.isNotEmpty) l10n?.videosCount(formattedVideos),
      if (creatorProfile.isLive == true) l10n?.liveNow ?? '',
    ];
    final semanticStatsText = semanticStatsParts.isNotEmpty
        ? '${l10n?.commaSeparator ?? ','}${semanticStatsParts.whereType<String>().join(l10n?.commaSeparator ?? ',')}'
        : '';
    final semanticLabel =
        '${creatorProfile.name}, @${creatorProfile.id}$semanticStatsText';

    final showSubscribe = isSubscribed != null && onToggleSubscribe != null;

    // `excludeSemantics: true` drops the InkWell's tap action, so the same
    // callback has to be declared on the Semantics node as well.
    final handleTap = onTap != null
        ? () {
            HapticFeedback.lightImpact();
            onTap!();
          }
        : null;

    final content = Tooltip(
      message: creatorProfile.name,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabel,
        onTap: handleTap,
        excludeSemantics: true,
        child: InkWell(
          onTap: handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22, // 固定头像大小
                  backgroundColor: colorScheme.primaryContainer,
                  // ⚡ Bolt Optimization: Wrap provider with ResizeImage.resizeIfNeeded.
                  // Avatar visual size is 44x44px. Capping decode resolution to 128x128px
                  // avoids decoding high-res 1080p/4K network avatar images into full GPU RAM,
                  // saving ~2MB-8MB RAM per item and reducing UI/Raster thread decode jank on scroll.
                  backgroundImage:
                      creatorProfile.thumbnailUrl != null &&
                          creatorProfile.thumbnailUrl!.isNotEmpty
                      ? ResizeImage.resizeIfNeeded(
                          128,
                          128,
                          CachedNetworkImageProvider(
                            creatorProfile.thumbnailUrl!,
                          ),
                        )
                      : null,
                  child:
                      (creatorProfile.thumbnailUrl == null ||
                          creatorProfile.thumbnailUrl!.isEmpty)
                      ? Text(
                          creatorProfile.name.isNotEmpty
                              ? creatorProfile.name[0].toUpperCase()
                              : '?',
                          style: $styles.text.bodySmallBold.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // 垂直完美居中
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creatorProfile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                if (!showSubscribe)
                  Icon(AppIcons.chevronRight, color: $styles.colors.outline),
              ],
            ),
          ),
        ),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: showSubscribe
          ? Row(
              children: [
                Expanded(child: content),
                Padding(
                  padding: EdgeInsets.only(right: $styles.insets.xs),
                  child: CreatorSubscribeButton(
                    isSubscribed: isSubscribed!,
                    onPressed: onToggleSubscribe!,
                    compact: true,
                  ),
                ),
              ],
            )
          : content,
    );
  }
}
