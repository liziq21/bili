import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/app_database.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../../ui/video_card.dart';

/// 一条动态条目
class const FeedEntryTile({
  super.key,
  required final FeedEntryEntity entry,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final publishedAt = entry.publishedAt;

    return ListTile(
      onTap: onTap,
      leading: _thumbnail(colorScheme),
      title: Text(
        entry.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: $styles.text.body.copyWith(
          color: colorScheme.onSurface,
          // 未读加粗：角标只给数量，逐条区分只能靠字重。
          fontWeight: entry.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: publishedAt == null
          ? null
          : Text(
              VideoCard.formatRelativeDate(publishedAt, l10n),
              style: $styles.text.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }

  Widget _thumbnail(ColorScheme colorScheme) {
    final url = entry.thumbnailUrl;
    final fallback = SizedBox(
      width: 72,
      height: 40,
      child: Icon(Icons.movie_outlined, color: colorScheme.onSurfaceVariant),
    );
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular($styles.corners.sm),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 72,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, url, error) => fallback,
      ),
    );
  }
}
