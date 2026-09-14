import 'package:chopper/chopper.dart';

part 'yt_api.chopper.dart';

@ChopperApi(baseUrl: 'https://www.youtube.com')
abstract class YoutubeApi extends ChopperService {
  @POST(path: '/youtubei/v1/search')
  Future<Response<Map<String, dynamic>>> search(
    @body Map<String, dynamic> body,
  );

  @POST(path: '/youtubei/v1/player')
  Future<Response<Map<String, dynamic>>> getPlayer(
    @body Map<String, dynamic> body,
  );

  @GET(path: 'https://suggestqueries.google.com/complete/search')
  Future<Response<String>> getSearchSuggestions(
    @Query('q') String query, {
    @Query('client') String searchClient = 'youtube',
    @Query('ds') String ds = 'yt',
  });

  static YoutubeApi create([ChopperClient? client]) =>
      _$YoutubeApi(client ?? .new());
}
