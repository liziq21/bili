import 'package:data/data.dart';

mixin class YouTubeRemoteDataSource implements RemoteDataSource {
  static const String youtubeSourceId = 'youtube';

  @override
  String get sourceId => youtubeSourceId;
}
