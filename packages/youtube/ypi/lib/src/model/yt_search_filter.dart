enum const YoutubeUploadDateFilter(final String label, final int value) {
  lastHour('1小时内', 1),
  today('今天', 2),
  thisWeek('本周', 3),
  thisMonth('本月', 4),
  thisYear('本年', 5),
}

enum const YoutubeContentTypeFilter(final String label, final int value) {
  video('视频', 1),
  channel('频道', 2),
  playlist('播放列表', 3),
  movie('电影', 4),
}

enum const YoutubeDurationFilter(final String label, final int value) {
  under4Minutes('4分钟以下', 1),
  fourTo20Minutes('4-20分钟', 2),
  over20Minutes('20分钟以上', 3),
}

enum const YoutubeFeatureFilter(final String label, final int fieldTag) {
  live('直播', 4),
  fourK('4K', 5),
  hd('高清', 6),
  subtitles('字幕/CC', 7),
  creativeCommons('知识共享', 8),
  threeD('3D', 9),
  threeSixty('360°', 11),
  hdr('HDR', 14),
}
