import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

abstract interface class VideoDetailRepository {
  Future<Result<VideoDetail>> getVideoDetail(String id);
  Future<Result<bool>> toggleLike(String id, bool isLiked);
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited);
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed);
}

class AppVideoDetailRepository implements VideoDetailRepository {
  AppVideoDetailRepository([this._remoteDataSource]);

  final VideoDetailRemoteDataSource? _remoteDataSource;

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.getVideoDetail(id);
    }
    return Result.error(Exception('当前数据源不支持获取视频详情'));
  }

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.toggleLike(id, isLiked);
    }
    return Result.ok(!isLiked);
  }

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.toggleFavorite(id, isFavorited);
    }
    return Result.ok(!isFavorited);
  }

  @override
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.toggleSubscribe(creatorId, isSubscribed);
    }
    return Result.ok(!isSubscribed);
  }
}
