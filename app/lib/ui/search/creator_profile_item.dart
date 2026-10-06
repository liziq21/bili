import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';

class const CreatorProfileItem({
  super.key,
  required final CreatorProfile creatorProfile,
  final Function()? onTap,
}) extends StatelessWidget {
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
    Theme.of(context);

    final semanticLabel = '${creatorProfile.name}, @${creatorProfile.id}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: creatorProfile.name,
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22, // 固定头像大小
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
                          '@${creatorProfile.id}',
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: $styles.colors.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
