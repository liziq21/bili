import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

/// 视频详情 Repository 接口
///
/// 包含获取视频详细信息、点赞、收藏及关注创作者等交互逻辑。
abstract interface class VideoDetailRepository() {
  /// 获取指定 ID 视频的详细信息
  Future<Result<VideoDetail>> getVideoDetail(String id);

  /// 切换视频的点赞状态
  Future<Result<bool>> toggleLike(String id, bool isLiked);

  /// 切换视频的收藏状态
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited);

  /// 切换对创作者的关注状态
  Future<Result<bool>> toggleSubscribe(String creatorId, bool isSubscribed);

  /// 解析指定视频的可播放地址
  ///
  /// [preferHeight] 为期望的画面高度，源按自身可用清晰度就近选取；为
  /// null 时由源取默认档。播放地址带签名时效，调用方取到即播。
  Future<Result<MediaStream>> getMediaStream(String id, {int? preferHeight});
}

/// [VideoDetailRepository] 的默认应用实现
///
/// 依赖可选的 [VideoDetailRemoteDataSource] 与 [MediaStreamRemoteDataSource]
/// 能力接口。当当前数据源未实现该能力时返回错误：假成功比失败更糟，调用方
/// 会据此回滚乐观更新，而假成功会让界面停在一个从未被持久化的状态上。
class AppVideoDetailRepository([
  final VideoDetailRemoteDataSource? _remoteDataSource,
  final MediaStreamRemoteDataSource? _mediaStreamDataSource,
]) implements VideoDetailRepository {
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
    return Result.error(Exception('当前数据源不支持点赞'));
  }

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.toggleFavorite(id, isFavorited);
    }
    return Result.error(Exception('当前数据源不支持收藏'));
  }

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async {
    if (_remoteDataSource != null) {
      return _remoteDataSource.toggleSubscribe(creatorId, isSubscribed);
    }
    return Result.error(Exception('当前数据源不支持关注创作者'));
  }

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async {
    if (_mediaStreamDataSource != null) {
      return _mediaStreamDataSource.getMediaStream(
        id,
        preferHeight: preferHeight,
      );
    }
    return Result.error(Exception('当前数据源不支持获取播放地址'));
  }
}
