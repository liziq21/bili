import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_remote_data_source.dart';

/// 播放地址可用性探测：地址在超时前送出第一批字节即视为可用。
typedef LiveStreamUrlProbe = Future<bool> Function(
  String url,
  Map<String, String> headers,
);

/// 探测候选地址是否真的可播。
///
/// 只等第一批字节就断开：HLS 是 m3u8 文本，FLV 是流首部，两者都会在毫秒级
/// 给出数据；迟迟没有字节的地址正是「HTTP 000、20 秒无响应」那一类，只发
/// HEAD 或只看状态码都区分不出来。
Future<bool> probeLiveStreamUrl(
  String url,
  Map<String, String> headers, {
  http.Client Function() clientFactory = http.Client.new,
  Duration timeout = _probeTimeout,
}) async {
  // 相对地址或非 http(s) 的候选在 `Client.send` 里会抛 ArgumentError；
  // 提前判掉，免得它看起来像「请求构造失败」而掩盖真正的原因。
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }
  final client = clientFactory();
  try {
    // 响应头与首批字节共用同一个预算：两段各自计时会让一个候选最多等
    // 8 秒，串行回退时后面的候选全被拖住。
    final deadline = Stopwatch()..start();
    final send = client.send(http.Request('GET', uri)..headers.addAll(headers));
    // 超时之后原请求仍会以错误收尾；先挂监听，免得变成未处理异常。
    send.ignore();
    final response = await send.timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 400) return false;
    final remaining = timeout - deadline.elapsed;
    if (remaining <= Duration.zero) return false;
    final firstByte = response.stream.first;
    firstByte.ignore();
    await firstByte.timeout(remaining);
    return true;
  } on Object {
    return false;
  } finally {
    client.close();
  }
}

const _probeTimeout = Duration(seconds: 4);

/// 一条可尝试的直播流地址，连同解析出它的 codec（档位与 acceptQn 在 codec 上）。
typedef _StreamCandidate = ({String url, NetworkLiveStreamCodec codec});

/// B站直播间详情与直播流地址数据源。
///
/// 把 B 站的直播间详情 DTO（`NetworkLiveRoomDetail`）与播放信息
/// （`NetworkLiveRoomPlayInfo`）收敛为中立的 [LiveRoomDetail] 与
/// [MediaStream]，app 层不感知 B 站的 roomInfo/anchorInfo/watchedShow
/// 与 playurl 嵌套结构。
final class BiliLiveRoomDetailRemoteDataSource({
  required final NetworkLiveDataSource network,
  required final String browserUserAgent,

  /// 候选地址探测，默认见 [probeLiveStreamUrl]；测试注入 fake 以免联网。
  final LiveStreamUrlProbe probe = probeLiveStreamUrl,

  /// 播放器跑在浏览器里。浏览器解不了 FLV，候选排序要把 HLS 提到前面；
  /// 默认取 [kIsWeb]，测试可注入以覆盖两种排序。
  final bool browserPlayer = kIsWeb,
}) extends LiveRoomDetailRemoteDataSource with BiliRemoteDataSource {
  Map<String, String> get _headers => {
    'User-Agent': browserUserAgent,
    'Referer': 'https://www.bilibili.com/',
  };

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    try {
      if (roomId <= 0) {
        return Result.error(Exception('Live room ID must be positive'));
      }
      final detail = await network.getLiveRoomDetail(roomId: roomId);
      final roomInfo = detail.roomInfo;
      if (roomInfo == null) {
        return Result.error(Exception('直播间 $roomId 未返回房间信息'));
      }
      final anchorName = detail.anchorInfo?.baseInfo?.uname ?? '未知主播';
      final online = detail.watchedShow?.num ?? roomInfo.online ?? 0;
      final isLive = roomInfo.liveStatus == 1;
      return Result.success(
        LiveRoomDetail(
          roomId: roomId,
          title: roomInfo.title ?? '未知标题',
          anchorName: anchorName,
          online: online,
          coverUrl: normalizeBiliUrl(roomInfo.cover),
          isLive: isLive,
          areaName: roomInfo.parentAreaName ?? roomInfo.areaName,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) async {
    try {
      if (roomId <= 0) {
        return Result.error(Exception('Live room ID must be positive'));
      }
      // 切清晰度 = 带 qn 重新请求：响应里对应档的 codec 条目带着该档的
      // 流地址（其 currentQn 即目标档）。preferQn 为 null 时沿用默认档。
      final playInfo = await network.getLiveRoomPlayInfo(
        roomId: roomId,
        qn: preferQn ?? 10000,
      );
      final playurl = playInfo.playurlInfo?.playurl;
      if (playurl == null || playurl.stream.isEmpty) {
        return Result.error(Exception('直播间 $roomId 未返回可用流'));
      }

      final candidates = _streamCandidates(playurl, preferQn: preferQn);
      if (candidates.isEmpty) {
        return Result.error(Exception('直播间 $roomId 未返回流地址'));
      }

      // 逐个探测，第一个真的能送出数据的候选就是可播地址。只按协议挑一路
      // 会撞上「地址在但连接无响应」的那类候选，而播放器对这种情况不报错，
      // 只会一直停在首帧。
      for (final candidate in candidates) {
        if (!await _probe(candidate.url)) continue;
        final currentQn = candidate.codec.currentQn;
        return Result.success(
          MediaStream(
            videoUrl: candidate.url,
            headers: _headers,
            // qn 是直播档的源侧身份：记忆「上次选了哪一档」与界面标记当前
            // 档都用它，与点播的 dash video id 同位。
            streamId: currentQn,
            qualityLabel: _qualityLabel(playurl.gQnDesc, currentQn),
            alternatives: _qualityOptions(
              gQnDesc: playurl.gQnDesc,
              acceptQn: candidate.codec.acceptQn,
              currentQn: currentQn,
            ),
          ),
        );
      }
      return Result.error(Exception('直播间 $roomId 的所有候选地址均不可用'));
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// 探测一路候选；探测自身出错（URL 非法、请求构造失败）只说明这一路不可
  /// 用，不能让整个候选循环中断。
  Future<bool> _probe(String url) async {
    try {
      return await probe(url, _headers);
    } on Object {
      return false;
    }
  }

  /// 展开全部候选地址，顺序为：
  ///
  /// 1. 命中请求档位的 codec 优先——切清晰度时不能因为 FLV 先探测成功就停
  ///    在别的档，哪怕 HLS 上有用户选的那一档。
  /// 2. 然后按「FLV → HLS(fmp4) → HLS(ts) → 其他」：实测同一房间的 FLV 全部
  ///    可播，而 HLS-TS 对多数房间 20 秒无响应，FLV 排在前面让探测通常一次
  ///    命中。
  /// 3. 同格式内 avc 先于 hevc：HEVC 在部分设备上解不出来，选档不该顺带把
  ///    编码格式也换掉。
  ///
  /// 同一格式的每一路 codec 都会展开：只试选中的那一路时，它挂了就只剩别的
  /// 封装，用户看到的是「换了个格式」而不是同一档的另一个编码。
  List<_StreamCandidate> _streamCandidates(
    NetworkLivePlayurlData playurl, {
    int? preferQn,
  }) {
    final ranked =
        <({NetworkLiveStreamCodec codec, int transport, int target})>[];
    for (final stream in playurl.stream) {
      final protocol = _protocolRank(stream.protocolName) * 10;
      for (final format in stream.format) {
        final transport = protocol + _formatRank(format.formatName);
        for (final codec in format.codec) {
          if (codec.baseUrl == null || codec.urlInfo.isEmpty) continue;
          ranked.add((
            codec: codec,
            transport: transport,
            target: _targetRank(codec, preferQn),
          ));
        }
      }
    }

    // 排序稳定（List.sort 不保证稳定，所以并列时用 codec 的原始位置兜底）：
    // 档位命中 → 封装 → avc 先于 hevc → 源侧顺序。
    final positions = {for (final (i, e) in ranked.indexed) e: i};
    ranked.sort((a, b) {
      final byTarget = a.target.compareTo(b.target);
      if (byTarget != 0) return byTarget;
      final byTransport = a.transport.compareTo(b.transport);
      if (byTransport != 0) return byTransport;
      final byCodec = (a.codec.codecName == 'avc' ? 0 : 1).compareTo(
        b.codec.codecName == 'avc' ? 0 : 1,
      );
      if (byCodec != 0) return byCodec;
      return positions[a]!.compareTo(positions[b]!);
    });

    final candidates = <_StreamCandidate>[];
    final seen = <String>{};
    for (final entry in ranked) {
      for (final urlInfo in entry.codec.urlInfo) {
        final raw =
            '${urlInfo.host ?? ''}${entry.codec.baseUrl ?? ''}'
            '${urlInfo.extra ?? ''}';
        final url = normalizeBiliUrl(raw);
        if (url == null || url.isEmpty || !seen.add(url)) continue;
        candidates.add((url: url, codec: entry.codec));
      }
    }
    return candidates;
  }

  /// 请求的档位命中为 0，其余为 1；没请求档位时全部并列。
  int _targetRank(NetworkLiveStreamCodec codec, int? preferQn) =>
      preferQn == null || codec.currentQn == preferQn ? 0 : 1;

  int _protocolRank(String? protocol) => switch (protocol) {
    // 浏览器播放器解不了 FLV：Web 上把 FLV 压到未知协议同一档，让 HLS 先探测。
    'http_stream' => browserPlayer ? 2 : 0,
    'http_hls' => 1,
    _ => 2,
  };

  int _formatRank(String? format) => switch (format) {
    'fmp4' => 0,
    'ts' => 1,
    _ => 2,
  };

  /// gQnDesc 里 qn → 可读描述。找不到时退回 `{qn}`，保证标签非空。
  String _qualityLabel(List<NetworkLiveQualityDescription> gQnDesc, int? qn) {
    if (qn == null) return '';
    final description = gQnDesc.firstWhere(
      (item) => item.qn == qn,
      orElse: () => NetworkLiveQualityDescription(qn: qn, desc: null),
    );
    return description.desc ?? '$qn';
  }

  /// 可切换档位列表：acceptQn 与 gQnDesc 的交集，排除当前档，保持
  /// gQnDesc 顺序（源侧即清晰度降序）。
  List<MediaQualityOption> _qualityOptions({
    required List<NetworkLiveQualityDescription> gQnDesc,
    required List<int> acceptQn,
    required int? currentQn,
  }) {
    return gQnDesc
        .where(
          (item) =>
              item.qn != null &&
              item.qn != currentQn &&
              acceptQn.contains(item.qn),
        )
        .map(
          (item) => MediaQualityOption(
            streamId: item.qn,
            label: item.desc ?? '${item.qn}',
          ),
        )
        .toList();
  }
}
