import 'remote_data_source.dart';

abstract class const MediaSource() {
  String get id;
  String get name;

  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;
  CreatorProfileSearchRemoteDataSource? get creatorProfileSearchDataSource =>
      null;
  LiveRoomSearchRemoteDataSource? get liveRoomSearchDataSource => null;
  VideoSearchRemoteDataSource? get videoSearchDataSource => null;
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => null;

  VideoDetailRemoteDataSource? get videoDetailDataSource => null;
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;
  DanmakuRemoteDataSource? get danmakuDataSource => null;
  MediaStreamRemoteDataSource? get mediaStreamDataSource => null;

  /// 直播间详情与直播流地址能力（可选）。
  LiveRoomDetailRemoteDataSource? get liveRoomDetailDataSource => null;

  List<VideoFeedRemoteDataSource> get videoFeedDataSources => const [];
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  Future<void> close() async {}
}
