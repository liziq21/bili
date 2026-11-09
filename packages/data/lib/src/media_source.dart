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
  LiveDanmakuRemoteDataSource? get liveDanmakuDataSource => null;
  MediaStreamRemoteDataSource? get mediaStreamDataSource => null;

  /// 直播间详情与直播流地址能力（可选）。
  LiveRoomDetailRemoteDataSource? get liveRoomDetailDataSource => null;

  /// 频道投稿视频分页能力（订阅 Feed 消费用，可选）。
  UserVideosRemoteDataSource? get userVideosDataSource => null;

  /// 远端播放列表内容能力（可选）。
  PlaylistContentRemoteDataSource? get playlistContentDataSource => null;

  List<VideoFeedRemoteDataSource> get videoFeedDataSources => const [];
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  Future<void> close() async {}
}
