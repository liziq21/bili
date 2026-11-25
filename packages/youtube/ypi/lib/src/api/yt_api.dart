import 'package:chopper/chopper.dart';

part 'yt_api.chopper.dart';

@ChopperApi(baseUrl: 'https://www.youtube.com')
abstract class YoutubeApi extends ChopperService {
  @POST(path: '/youtubei/v1/search')
  Future<Response<Map<String, dynamic>>> search(
    @body Map<String, dynamic> body,
  );

  @POST(path: '/youtubei/v1/browse')
  Future<Response<Map<String, dynamic>>> browse(
    @body Map<String, dynamic> body,
  );

  @POST(path: '/youtubei/v1/next')
  Future<Response<Map<String, dynamic>>> next(@body Map<String, dynamic> body);

  @POST(path: '/youtubei/v1/player')
  Future<Response<Map<String, dynamic>>> player(
    @body Map<String, dynamic> body,
  );

  @POST(path: '/youtubei/v1/navigation/resolve_url')
  Future<Response<Map<String, dynamic>>> resolveUrl(
    @body Map<String, dynamic> body,
  );

  @POST(
    path: 'https://music.youtube.com/youtubei/v1/music/get_search_suggestions',
  )
  Future<Response<Map<String, dynamic>>> getMusicSearchSuggestions(
    @body Map<String, dynamic> body,
  );

  @POST(path: 'https://music.youtube.com/youtubei/v1/search')
  Future<Response<Map<String, dynamic>>> musicSearch(
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
