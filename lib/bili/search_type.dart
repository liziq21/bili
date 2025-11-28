import 'package:json_annotation/json_annotation.dart';

part 'search_type.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: FieldRename.snake)
enum SearchType {
  article,
  biliUser,
  photo,
  topic,
  mediaBangumi,
  mediaFt,
  live,
  liveRoom,
  liveUser,
  video;
}

/* 应该分离
class SearchConfig {
  const SearchConfig({
    this.type,
    this.text,
    this.order,
    //this.filter,
  })
  
  final SearchType type;
  final String text;
  final List<SearchOrder>? order;

  
  static get Map<, String> types => {
    .video: '视频',
    .mediaBangumi: '番剧',
    .mediaFt: '影视',
    .live: '直播',
    .biliUser: '用户',
    .article: '专栏',
  }
}*/