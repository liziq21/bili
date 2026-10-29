/// getDanmuInfo 接口响应（拆掉 {code, data} 信封后的 data 部分）。
class NetworkLiveDanmakuInfo {
  const NetworkLiveDanmakuInfo({
    required this.token,
    required this.host,
    required this.wssPort,
  });

  /// 弹幕服务器鉴权 token。
  final String token;

  /// 弹幕服务器主机名（取 host_list 第一项）。
  final String host;

  /// 弹幕服务器 WSS 端口（取 host_list 第一项）。
  final int wssPort;

  factory NetworkLiveDanmakuInfo.fromJson(Map<String, dynamic> json) {
    final hostList = json['host_list'];
    final first = hostList is List && hostList.isNotEmpty
        ? hostList.first as Map<String, dynamic>
        : const {};
    return NetworkLiveDanmakuInfo(
      token: json['token'] as String? ?? '',
      host: first['host'] as String? ?? '',
      wssPort: (first['wss_port'] as int?) ?? 0,
    );
  }
}
