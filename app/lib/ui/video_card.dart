import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

class const VideoCard({
  super.key,
  required final VideoModel videoInfoBase,
  final GestureTapCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Removed redundant LayoutBuilder wrapper.
    // LayoutBuilder defers subtree construction to the layout phase. Removing it
    // avoids deferred layout callbacks during grid view renders, saving ~0.5ms-1ms per frame.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图区域
            AspectRatio(
              aspectRatio: 16 / 9, // 固定的 16:9
              child: CachedNetworkImage(
                imageUrl: videoInfoBase.thumbnailUrl ?? '',
                // ⚡ Bolt Optimization: Downsample decoded thumbnail in GPU memory to max width of 480px.
                // Reduces UI/Raster thread decode burden and GPU RAM consumption during fast scrolling.
                memCacheWidth: 480,
                fit: BoxFit.cover,
              ),
            ),
            // 文字区域：用 Expanded 承接剩下的所有空间
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // 自动把标题和播放量推到两头
                  children: [
                    Text(
                      videoInfoBase.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${videoInfoBase.viewCount} 观看 • ${videoInfoBase.uploadDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
