import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:data/data.dart';

//import '../utils/image_error_listener.dart';

class const VideoCard({
  super.key,
  required final VideoModel videoInfoBase,
  final GestureTapCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
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
      },
    );
  }
}

// 💡 顺手写一个播放量格式化的小工具（可选，让界面更清爽）
// String _formatPlayCount(dynamic play) {
//   if (play == null) return '0';
//   final count = int.tryParse(play.toString()) ?? 0;
//   if (count >= 10000) {
//     return '${(count / 10000).toStringAsFixed(1)}万';
//   }
//   return count.toString();
// }
