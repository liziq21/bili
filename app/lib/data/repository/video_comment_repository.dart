import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

/// 视频评论 Repository 接口
///
/// 提供视频评论列表的分页获取功能。
abstract interface class VideoCommentRepository() {
  /// 分页获取指定视频的评论列表
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  });
}

/// [VideoCommentRepository] 的默认应用实现
///
/// 依赖可选的 [VideoCommentRemoteDataSource] 能力接口。
/// 当当前数据源未实现评论功能时，安全返回错误结果。
class AppVideoCommentRepository([final VideoCommentRemoteDataSource? _remoteDataSource]) implements VideoCommentRepository {
  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.getVideoComments(
        videoId,
        page: page,
        pageSize: pageSize,
      );
    }
    return Result.error(Exception('当前数据源不支持获取评论'));
  }
}
