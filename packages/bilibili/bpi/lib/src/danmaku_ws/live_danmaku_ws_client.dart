import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'danmaku_message.dart';
import 'packet.dart';

/// B站直播弹幕 WebSocket 客户端。
///
/// 连接 wss://`host`:`wssPort`/sub → 发送鉴权包（op=7，JSON 包体，
/// protover=2 声明期望 JSON 消息）→ 30s 心跳（op=2）→ 解析弹幕消息流
/// （op=5）。断线后按退避重连。
///
/// 调用方订阅 [messages] 即触发连接；末次取消订阅即断开并停止重连。
class LiveDanmakuWsClient {
  LiveDanmakuWsClient({
    required this.host,
    required this.wssPort,
    required this.roomId,
    required this.token,
    required this.buvid,
    this.uid = 0,
    this.scheme = 'wss',
  });

  final String host;
  final int wssPort;
  final int roomId;
  final String token;
  final String buvid;
  final int uid;
  final String scheme;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const List<Duration> _reconnectBackoff = [
    Duration(seconds: 3),
    Duration(seconds: 6),
    Duration(seconds: 12),
    Duration(seconds: 30),
  ];
  static const int _maxBuffer = 64 * 1024;

  StreamController<DanmakuMessage>? _controller;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  List<int> _buffer = [];
  int _reconnectAttempt = 0;
  bool _stopped = false;

  /// 弹幕消息流。首次订阅触发连接；末次取消触发断开。
  Stream<DanmakuMessage> get messages {
    _controller ??= StreamController<DanmakuMessage>.broadcast(
      onListen: () {
        if (!_stopped) _connect();
      },
      onCancel: () {
        _stopped = true;
        _close();
      },
    );
    return _controller!.stream;
  }

  Future<void> _connect() async {
    if (_stopped) return;
    final uri = Uri.parse('$scheme://$host:$wssPort/sub');
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
      if (_stopped) {
        channel.sink.close();
        return;
      }
      _sendAuth();
      _startHeartbeat();
      _reconnectAttempt = 0;
      channel.stream.listen(
        (data) {
          if (data is Uint8List) _handleBinary(data);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } on Object {
      channel?.sink.close();
      _scheduleReconnect();
    }
  }

  void _sendAuth() {
    final bodyBytes = utf8.encode(
      jsonEncode({
        'uid': uid,
        'roomid': roomId,
        'protover': 2,
        'buvid': buvid,
        'platform': 'web',
        'type': 2,
        'key': token,
      }),
    );
    _send(
      WsPacket(
        packetLen: 16 + bodyBytes.length,
        headerLen: 16,
        protocolVersion: 1,
        operation: WsOperation.auth.code,
        sequence: 1,
        body: bodyBytes,
      ).encode(),
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_stopped) return;
      _send(
        WsPacket(
          packetLen: 16,
          headerLen: 16,
          protocolVersion: 0,
          operation: WsOperation.heartbeat.code,
          sequence: 1,
        ).encode(),
      );
    });
  }

  void _send(List<int> bytes) {
    _channel?.sink.add(Uint8List.fromList(bytes));
  }

  void _handleBinary(List<int> data) {
    _buffer.addAll(data);
    if (_buffer.length > _maxBuffer) {
      _buffer = [];
      return;
    }
    while (true) {
      try {
        final (packet, rest) = WsPacket.split(_buffer);
        _buffer = rest;
        _handlePacket(packet);
      } on FormatException {
        break;
      }
    }
  }

  void _handlePacket(WsPacket packet) {
    if (packet.protocolVersion == 2) {
      // zlib 压缩的包体：解压后可能包含多个包，递归处理。
      final decompressed = _decompress(packet.body);
      if (decompressed.isNotEmpty) {
        _handleBinary(decompressed);
      }
      return;
    }
    if (packet.operation == WsOperation.message.code) {
      final message = DanmakuMessage.parse(packet.body);
      if (message != null) {
        _controller?.add(message);
      }
    }
    // heartbeatReply / authReply：忽略。
  }

  List<int> _decompress(List<int> body) {
    try {
      final codec = ZLibCodec();
      return codec.decode(Uint8List.fromList(body));
    } on Object {
      return [];
    }
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _close();
    final delay =
        _reconnectBackoff[_reconnectAttempt % _reconnectBackoff.length];
    _reconnectAttempt++;
    Timer(delay, () {
      if (!_stopped) _connect();
    });
  }

  void _close() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channel?.sink.close();
    _channel = null;
    _buffer = [];
  }
}
