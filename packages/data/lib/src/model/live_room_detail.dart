/// 直播间详情的中立模型。
///
/// 各服务源的直播间详情 DTO 在此映射为源无关字段，app 层只消费本模型，
/// 不感知 B 站的 roomInfo / anchorInfo / watchedShow 结构。
class const LiveRoomDetail({
  required final int roomId,

  /// 直播间标题。
  required final String title,

  /// 主播昵称。
  required final String anchorName,

  /// 在线人数（取 watchedShow.num，缺省时退回 roomInfo.online）。
  required final int online,

  /// 直播间封面图地址。
  final String? coverUrl,

  /// 是否正在直播（liveStatus == 1）。
  required final bool isLive,

  /// 分区名称（优先取 parentAreaName，退回 areaName）。
  final String? areaName,
});
