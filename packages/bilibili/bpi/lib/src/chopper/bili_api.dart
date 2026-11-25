import 'dart:io';

import 'package:chopper/chopper.dart';

import '../api.dart';
import '../model/feed/network_bili_home_feed.dart';
import '../model/feed/network_bili_popular_response.dart';
import '../model/feed/network_bili_ranking_response.dart';
import '../model/live/network_live_danmaku_info.dart';
import '../model/live/network_live_recommended_rooms.dart';
import '../model/live/network_live_room_base_info.dart';
import '../model/live/network_live_room_detail.dart';
import '../model/live/network_live_room_play_info.dart';
import '../model/live/network_live_status_by_uids.dart';
import '../model/reply/network_reply_data.dart';
import '../model/reply/network_reply_reply_data.dart';
import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import '../model/user/network_bili_playlist_content.dart';
import '../model/user/network_bili_series_archives.dart';
import '../model/user/network_bili_user_article.dart';
import '../model/user/network_bili_user_card.dart';
import '../model/user/network_bili_user_videos.dart';
import '../model/video/network_bangumi_play_url_v2.dart';
import '../model/video/network_bangumi_season.dart';
import '../model/video/network_bili_player_info.dart';
import '../model/video/network_bili_video_parts.dart';
import '../model/video/network_bili_video_snapshot.dart';
import '../model/video/network_bili_video_tags.dart';
import '../model/video/network_play_url.dart';
import '../model/video/network_related_video.dart';
import '../model/video/network_video_relation.dart';
import '../model/video/video_detail_data.dart';
import '../search_type.dart';

part 'bili_api.chopper.dart';

@ChopperApi(baseUrl: Api.base)
abstract class BiliNetworkApi extends ChopperService {
  @GET(
    path: SearchApi.suggest,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  )
  Future<NetworkSearchSuggest> getSuggests(
    @query String term,
    @query String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);

  @GET(path: WbiApiPath.searchAll)
  Future<NetworkSearchResult> searchAll(
    @query String keyword, {
    @query int? page,
    @tag String tag = 'WBI',
  });

  @GET(path: WbiApiPath.searchByType)
  Future<NetworkSearchResult> typeSearch(
    @Query('search_type') SearchType searchType,
    @query String keyword, {
    @query int? page,
    @query String? order,
    @query String? duration,
    @query String? tids,
    @Query('order_sort') String? orderSort,
    @Query('user_type') String? userType,
    @Query('category_id') String? categoryId,
    @Query('pubtime_begin_s') String? pubTimeBeginS,
    @Query('pubtime_end_s') String? pubTimeEndS,
    @tag String tag = 'WBI',
  });

  @GET(path: ApiPath.videoIntro)
  Future<VideoDetailData> videoIntro({@query required String bvid});

  @GET(path: ApiPath.videoParts)
  Future<NetworkBiliVideoParts> getVideoParts({@query required String bvid});

  @GET(path: ApiPath.videoSnapshot)
  Future<NetworkBiliVideoSnapshot> getVideoSnapshot({
    @query required String bvid,
    @Query('index') int index = 1,
  });

  @GET(path: ApiPath.videoTags)
  Future<NetworkBiliVideoTags> getVideoTags({@query required String bvid});

  @GET(path: WbiApiPath.homeFeed)
  Future<NetworkBiliHomeFeed> getHomeFeed({
    @Query('fresh_type') int freshType = 3,
    @Query('ps') int pageSize = 12,
    @Query('version') int version = 1,
    @Query('feed_version') String feedVersion = 'V8',
    @tag String tag = 'WBI',
  });

  @GET(path: ApiPath.seriesArchives)
  Future<NetworkBiliSeriesArchives> getSeriesArchives({
    @query required int mid,
    @Query('series_id') required int seriesId,
    @Query('only_normal') bool onlyNormal = true,
    @Query('sort') String sort = 'desc',
    @Query('pn') int page = 1,
    @Query('ps') int pageSize = 30,
  });

  @GET(path: ApiPath.bangumiPlayUrlV2)
  Future<NetworkBangumiPlayUrlV2> getBangumiPlayUrlV2({
    @Query('ep_id') int? epId,
    @Query('cid') int? cid,
    @Query('qn') int qn = 80,
    @Query('fnval') int fnval = 4048,
    @Query('fourk') int fourk = 1,
  });

  @GET(path: ApiPath.videoRelation)
  Future<NetworkVideoRelation> getVideoRelation({@query required String bvid});

  @GET(path: ApiPath.relatedList)
  Future<NetworkRelatedVideosList> getRelatedVideos({
    @query required String bvid,
  });

  @GET(path: ApiPath.popular)
  Future<NetworkBiliPopularResponse> getPopular({
    @Query('pn') int page = 1,
    @Query('ps') int pageSize = 20,
  });

  @GET(path: ApiPath.ranking)
  Future<NetworkBiliRankingResponse> getRanking({
    @Query('rid') int rankingId = 0,
    @Query('type') String type = 'all',
  });

  @GET(path: ApiPath.replyListMain)
  Future<NetworkReplyData> getReplyListMain({
    @query required int oid,
    @query required int type,
    @Query('pagination_str') String? paginationStr,
    @query int? mode,
  });

  @GET(path: ApiPath.replyList)
  Future<NetworkReplyData> getReplyList({
    @query required int oid,
    @query required int type,
    @Query('pn') int? page,
    @query int? sort,
  });

  @GET(path: ApiPath.replyReplyList)
  Future<NetworkReplyReplyData> getReplyReplyList({
    @query required int oid,
    @query required int root,
    @query required int type,
    @Query('pn') int? page,
    @query int? sort,
  });

  @GET(path: WbiApiPath.playUrl)
  Future<NetworkPlayUrl> getPlayUrl(
    @query String bvid,
    @query int cid, {
    @query int qn = 80,
    @query int fnval = 4048,
    @query int fourk = 1,
    @Query('fnver') int fnver = 0,
    @Query('try_look') int tryLook = 1,
    @Query('web_location') int webLocation = 1315873,
    @Query('dm_img_list') String dmImgList = '[]',
    @Query('dm_img_str') required String dmImgStr,
    @Query('dm_cover_img_str') required String dmCoverImgStr,
    @Query('dm_img_inter') required String dmImgInter,
    @tag String tag = 'WBI',
  });

  @GET(path: ApiPath.playerV2)
  Future<NetworkBiliPlayerInfo> getPlayerInfo({
    @query required String bvid,
    @query required int cid,
  });

  @GET(path: LiveApi.roomDetail)
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({
    @Query('room_id') required int roomId,
  });

  @GET(path: LiveApi.roomPlayInfo)
  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    @Query('room_id') required int roomId,
    @Query('qn') int qn = 10000,
    @Query('protocol') String protocol = '0,1',
    @Query('format') String format = '0,1,2',
    @Query('codec') String codec = '0,1',
    @Query('platform') String platform = 'web',
    @Query('ptype') int ptype = 8,
  });

  @GET(path: LiveApi.danmuInfo)
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({
    @Query('id') required int roomId,
  });

  @GET(path: LiveApi.roomBaseInfo)
  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    @Query('room_ids') required List<int> roomIds,
    @Query('req_biz') String reqBiz = 'web',
  });

  @GET(path: LiveApi.statusByUids)
  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    @Query('uids[]') required List<int> uids,
  });

  @GET(path: LiveApi.recommendedRooms)
  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    @Query('page_size') int pageSize = 30,
    @Query('platform') String platform = 'web',
  });

  @GET(path: ApiPath.userCard)
  Future<NetworkBiliUserCardData> getUserCard({@query required int mid});

  @GET(path: ApiPath.userArticles)
  Future<NetworkBiliUserArticlesData> getUserArticles({
    @query required int mid,
    @Query('pn') int page = 1,
    @Query('ps') int pageSize = 30,
  });

  @GET(path: WbiApiPath.userVideos)
  Future<NetworkBiliUserVideosData> getUserVideos({
    @query required int mid,
    @Query('pn') int page = 1,
    @Query('ps') int pageSize = 30,
    @Query('order') String? order,
    @tag String tag = 'WBI',
  });

  @GET(path: ApiPath.bangumiSeason)
  Future<NetworkBangumiSeasonData> getBangumiSeason({
    @Query('season_id') int? seasonId,
    @Query('ep_id') int? epId,
  });

  @GET(path: ApiPath.bangumiPlayUrl)
  Future<NetworkPlayUrl> getBangumiPlayUrl({
    @Query('ep_id') int? epId,
    @Query('cid') int? cid,
    @Query('qn') int qn = 80,
    @Query('fnval') int fnval = 4048,
    @Query('fourk') int fourk = 1,
  });

  @GET(path: WbiApiPath.playlistContent)
  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    @query required int mid,
    @Query('page_num') int pageNum = 1,
    @Query('page_size') int pageSize = 30,
    @Query('sort_reverse') bool sortReverse = false,
    @Query('season_id') int? seasonId,
    @tag String tag = 'WBI',
  });

  @GET(path: WbiApiPath.userPlaylists)
  Future<NetworkBiliPlaylistListData> getUserPlaylists({
    @query required int mid,
    @Query('page_num') int pageNum = 1,
    @Query('page_size') int pageSize = 30,
    @tag String tag = 'WBI',
  });

  static BiliNetworkApi create([ChopperClient? client]) =>
      _$BiliNetworkApi(client ?? .new());
}
