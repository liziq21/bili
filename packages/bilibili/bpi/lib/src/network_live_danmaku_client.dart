import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'model/live/network_live_danmaku.dart';
import 'network_live_data_source.dart';

/// Default WebSocket endpoint for Bilibili live danmaku.
const String _defaultDanmakuWsHost = 'broadcastlv.chat.bilibili.com';
const int _defaultDanmakuWsPort = 443;
const String _defaultDanmakuWsPath = '/sub';

/// Default heartbeat interval (seconds).
const int _defaultHeartbeatInterval = 30;

/// Implementation of [LiveDanmakuConnection] using [WebSocketChannel].
final class _LiveDanmakuConnectionImpl implements LiveDanmakuConnection {
  _LiveDanmakuConnectionImpl({
    required this.channel,
    required this.heartbeatInterval,
    required this.onClose,
  }) {
    _messageController = StreamController<LiveDanmakuMessage>.broadcast(
      onCancel: () {
        _messageController.close();
      },
    );
    _listen();
  }

  final WebSocketChannel channel;
  final int heartbeatInterval;
  final Future<void> Function() onClose;

  late final StreamController<LiveDanmakuMessage> _messageController;
  Timer? _heartbeatTimer;
  bool _closed = false;
  int _sequenceId = 1;

  @override
  Stream<LiveDanmakuMessage> get messages => _messageController.stream;

  @override
  bool get isConnected => !_closed && channel.closeCode == null;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _heartbeatTimer?.cancel();
    await channel.sink.close(ws_status.normalClosure);
    await onClose();
  }

  void _listen() {
    channel.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  void _onData(dynamic data) {
    if (data is List<int>) {
      _processBinaryData(data);
    } else if (data is String) {
      // Text frames are not expected in Bilibili protocol
      _processTextData(data);
    }
  }

  void _processBinaryData(List<int> data) {
    var offset = 0;
    while (offset < data.length) {
      if (data.length - offset < 16) {
        // Incomplete frame, wait for more data
        break;
      }
      final frame = LiveDanmakuFrame.decode(data.sublist(offset));
      offset += frame.packetLength;

      _handleFrame(frame);
    }
  }

  void _processTextData(String data) {
    // Bilibili live danmaku uses binary protocol, text is unexpected
    // But handle gracefully in case of protocol changes
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.fromString(json['cmd'] as String? ?? ''),
        payload: json,
        rawType: json['cmd'] as String?,
      );
      _messageController.add(message);
    } catch (_) {
      // Ignore unparseable text frames
    }
  }

  void _handleFrame(LiveDanmakuFrame frame) {
    switch (frame.opCode) {
      case LiveDanmakuOpCode.handshakeResponse:
        _handleHandshakeResponse(frame.body);
      case LiveDanmakuOpCode.heartbeatResponse:
        // Heartbeat ack, connection alive
        break;
      case LiveDanmakuOpCode.notification:
        _handleNotification(frame.body, frame.protocolVersion);
      case LiveDanmakuOpCode.disconnect:
        _handleDisconnect(frame.body);
      default:
        // Unknown op code, ignore
        break;
    }
  }

  void _handleHandshakeResponse(List<int> body) {
    try {
      final json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
      final response = LiveDanmakuHandshakeResponse.fromJson(json);
      if (!response.isSuccess) {
        _messageController.addError(
          Exception('Handshake failed: ${response.message ?? response.code}'),
        );
        close();
      } else {
        _startHeartbeat();
      }
    } catch (e) {
      _messageController.addError(
        Exception('Failed to parse handshake response: $e'),
      );
      close();
    }
  }

  void _handleNotification(List<int> body, LiveDanmakuProtocolVersion version) {
    List<int> payload = body;
    // Decompress if protocol version 2 (zlib/brotli)
    if (version == LiveDanmakuProtocolVersion.v2) {
      payload = _decompress(body);
    }

    try {
      final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      final cmd = json['cmd'] as String?;
      if (cmd == null) return;

      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.fromString(cmd),
        payload: json,
        rawType: cmd,
      );
      _messageController.add(message);
    } catch (e) {
      // Log parse error but don't crash
      // Could add logging here
    }
  }

  List<int> _decompress(List<int> data) {
    // Try zlib first (most common for v2)
    try {
      return ZLibDecoder().convert(data);
    } catch (_) {
      // Try brotli if available
      // Note: brotli support would need dart:io or a package
      // For now, return original if zlib fails
      return data;
    }
  }

  void _handleDisconnect(List<int> body) {
    // Server requested disconnect, could parse reason
    close();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: heartbeatInterval),
      (_) => _sendHeartbeat(),
    );
    _sendHeartbeat(); // Send immediately
  }

  void _sendHeartbeat() {
    if (_closed) return;
    final frame = LiveDanmakuFrame(
      opCode: LiveDanmakuOpCode.heartbeat,
      body: _int32ToBytes(_sequenceId++),
    );
    channel.sink.add(frame.encode());
  }

  void _onError(Object error) {
    _messageController.addError(error);
    close();
  }

  void _onDone() {
    if (!_closed) {
      _messageController.addError(Exception('WebSocket closed unexpectedly'));
    }
    _closed = true;
    _heartbeatTimer?.cancel();
    _messageController.close();
  }

  List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }
}

/// Live danmaku WebSocket client implementation.
final class LiveDanmakuClient {
  LiveDanmakuClient({
    String host = _defaultDanmakuWsHost,
    int port = _defaultDanmakuWsPort,
    String path = _defaultDanmakuWsPath,
    int heartbeatInterval = _defaultHeartbeatInterval,
  }) : _host = host,
       _port = port,
       _path = path,
       _heartbeatInterval = heartbeatInterval;

  final String _host;
  final int _port;
  final String _path;
  final int _heartbeatInterval;

  /// Connect to live danmaku WebSocket.
  LiveDanmakuConnection connect({
    required int roomId,
    required String token,
    int uid = 0,
    LiveDanmakuProtocolVersion protocolVersion = LiveDanmakuProtocolVersion.v2,
  }) {
    final uri = Uri(scheme: 'wss', host: _host, port: _port, path: _path);

    final channel = WebSocketChannel.connect(uri);
    final completer = Completer<void>();

    // Send handshake after connection
    channel.stream
        .firstWhere((data) => data is List<int>, orElse: () => null)
        .then((_) {
          final handshake = LiveDanmakuHandshakeRequest(
            roomId: roomId,
            uid: uid,
            token: token,
            protocolVersion: protocolVersion,
          );
          final frame = LiveDanmakuFrame(
            opCode: LiveDanmakuOpCode.handshakeRequest,
            body: utf8.encode(jsonEncode(handshake.toJson())),
            protocolVersion: protocolVersion,
          );
          channel.sink.add(frame.encode());
        });

    return _LiveDanmakuConnectionImpl(
      channel: channel,
      heartbeatInterval: _heartbeatInterval,
      onClose: () async {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
  }
}

/// BPI network data source extension for live danmaku.
extension NetworkLiveDataSourceDanmaku on NetworkLiveDataSource {
  /// Create a live danmaku WebSocket connection.
  ///
  /// The [token] should be obtained from the live room play info response
  /// (typically the `token` field in the danmaku server info).
  LiveDanmakuConnection connectLiveDanmaku({
    required int roomId,
    required String token,
    int uid = 0,
    LiveDanmakuProtocolVersion protocolVersion = LiveDanmakuProtocolVersion.v2,
  }) {
    final client = LiveDanmakuClient();
    return client.connect(
      roomId: roomId,
      token: token,
      uid: uid,
      protocolVersion: protocolVersion,
    );
  }
}
