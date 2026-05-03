class VideoInfoBase {
  const VideoInfoBase({
    required this.arcurl,
    required this.aid,
    required this.bvid,
    required this.title,
    required this.picUrl,
    required this.play,
    required this.pubdate,
    required this.duration,
    required this.desc,
    this.author,
  });

  final String arcurl;
  final int aid;
  final String bvid;
  final String title;
  final String picUrl;
  final int play;
  final int pubdate;
  final String duration;
  final String desc;
  final String? author;
}
