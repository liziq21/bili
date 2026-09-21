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

  List<VideoFeedRemoteDataSource> get videoFeedDataSources => const [];
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  Future<void> close() async {}
}
