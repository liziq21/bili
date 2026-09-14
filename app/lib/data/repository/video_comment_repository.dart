import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

abstract interface class VideoCommentRepository {
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  });
}

class AppVideoCommentRepository implements VideoCommentRepository {
  AppVideoCommentRepository([this._remoteDataSource]);

  final VideoCommentRemoteDataSource? _remoteDataSource;

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
