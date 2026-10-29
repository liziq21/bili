import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import 'bili_remote_data_source.dart';

/// B站弹幕数据源。
final class BiliDanmakuRemoteDataSource({
  required final NetworkVideoDataSource network,
}) extends DanmakuRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(
    String videoId,
  ) async {
    try {
      final sanitizedVideoId = videoId.replaceAll(_controlChars, '').trim();
      if (sanitizedVideoId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      final detail = await network.getVideoDetail(bvid: sanitizedVideoId);
      final cid = detail.pages?.firstOrNull?.cid;
      if (cid == null || cid <= 0) {
        return Result.error(Exception('视频没有可用分P，无法加载弹幕'));
      }

      final document = await network.getDanmaku(cid: cid);
      return Result.success(
        document.comments
            .map((comment) {
              final sanitizedContent = comment.content
                  .replaceAll(_controlChars, '')
                  .trim();
              return DanmakuComment(
                startTime: Duration(
                  microseconds:
                      (comment.startSeconds * Duration.microsecondsPerSecond)
                          .round(),
                ),
                mode: _modeOf(comment.mode),
                fontSize: comment.fontSize,
                colorArgb: 0xFF000000 | comment.color,
                content: sanitizedContent,
                rowId: comment.rowId,
              );
            })
            .where((comment) => comment.content.isNotEmpty)
            .toList(growable: false),
      );
    } catch (error) {
      return Result.error(error is Exception ? error : Exception('$error'));
    }
  }

  DanmakuMode _modeOf(int mode) {
    return switch (mode) {
      4 => DanmakuMode.bottom,
      5 => DanmakuMode.top,
      6 => DanmakuMode.reverse,
      7 || 8 => DanmakuMode.special,
      _ => DanmakuMode.scrolling,
    };
  }
}
