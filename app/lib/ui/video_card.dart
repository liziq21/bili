import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:data/data.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.videoInfoBase,
    this.onTap,
  });

  final VideoModel videoInfoBase;
  final GestureTapCallback? onTap;

  String _formatPlayCount(int? play) {
    if (play == null) return '0';
    if (play >= 10000) {
      return '${(play / 10000).toStringAsFixed(1)}万';
    }
    return play.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: videoInfoBase.thumbnailUrl != null &&
                      videoInfoBase.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: videoInfoBase.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url, error) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.video_library, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.video_library, color: Colors.white54),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      '${_formatPlayCount(videoInfoBase.viewCount)} 播放',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      ),
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
