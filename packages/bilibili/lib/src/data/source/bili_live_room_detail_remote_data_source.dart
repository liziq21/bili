import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
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
Future<bool> probeLiveStreamUrl(String url, Map<String, String> headers) async {
  final client = http.Client();
  final send = client.send(
    http.Request('GET', Uri.parse(url))..headers.addAll(headers),
  );
  // 超时之后原请求仍会以错误收尾；先挂监听，免得变成未处理异常。
  send.ignore();
  try {
    final response = await send.timeout(_probeTimeout);
    if (response.statusCode < 200 || response.statusCode >= 400) return false;
    final firstByte = response.stream.first;
    firstByte.ignore();
    await firstByte.timeout(_probeTimeout);
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
        if (!await probe(candidate.url, _headers)) continue;
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

  /// 展开全部候选地址，按「FLV → HLS(fmp4) → HLS(ts) → 其他」排序。
  ///
  /// 实测同一房间的 FLV 全部可播，而 HLS-TS 对多数房间 20 秒无响应，所以
  /// FLV 排在前面让探测通常一次命中；HLS 与多个 url_info host 仍作为后续
  /// 候选保留，单路失效不至于让整个直播间打不开。
  List<_StreamCandidate> _streamCandidates(
    NetworkLivePlayurlData playurl, {
    int? preferQn,
  }) {
    final candidates = <_StreamCandidate>[];
    final seen = <String>{};
    for (final stream in _stableSortBy(
      playurl.stream,
      (s) => _protocolRank(s.protocolName),
    )) {
      for (final format in _stableSortBy(
        stream.format,
        (f) => _formatRank(f.formatName),
      )) {
        final codec = _selectCodec(format.codec, preferQn);
        if (codec == null) continue;
        for (final urlInfo in codec.urlInfo) {
          final raw =
              '${urlInfo.host ?? ''}${codec.baseUrl ?? ''}${urlInfo.extra ?? ''}';
          final url = normalizeBiliUrl(raw);
          if (url == null || url.isEmpty || !seen.add(url)) continue;
          candidates.add((url: url, codec: codec));
        }
      }
    }
    return candidates;
  }

  /// 选一路 codec：优先命中请求的档，否则取当前档最高的一路。
  ///
  /// 源侧同一格式可能同时下发 avc 与 hevc，两路的 currentQn 不同（hevc 档
  /// 通常更高）。没有精确命中时优先 avc：HEVC 在部分设备上解不出来，选档
  /// 不该顺带把编码格式也换掉。
  NetworkLiveStreamCodec? _selectCodec(
    List<NetworkLiveStreamCodec> codecs,
    int? preferQn,
  ) {
    final playable = codecs
        .where((codec) => codec.baseUrl != null && codec.urlInfo.isNotEmpty)
        .toList();
    if (playable.isEmpty) return null;
    if (preferQn != null) {
      final exact = playable
          .where((codec) => codec.currentQn == preferQn)
          .toList();
      if (exact.isNotEmpty) return _highestQn(exact);
    }
    final avc = playable.where((codec) => codec.codecName == 'avc').toList();
    return _highestQn(avc.isEmpty ? playable : avc);
  }

  NetworkLiveStreamCodec _highestQn(List<NetworkLiveStreamCodec> codecs) =>
      codecs.reduce((a, b) => (b.currentQn ?? 0) > (a.currentQn ?? 0) ? b : a);

  int _protocolRank(String? protocol) => switch (protocol) {
    'http_stream' => 0,
    'http_hls' => 1,
    _ => 2,
  };

  int _formatRank(String? format) => switch (format) {
    'fmp4' => 0,
    'ts' => 1,
    _ => 2,
  };

  /// 按 rank 稳定排序：rank 相同时保持源侧顺序。
  List<T> _stableSortBy<T>(List<T> items, int Function(T) rank) {
    final indexed = items.indexed.toList()
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final (_, item) in indexed) item];
  }

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
