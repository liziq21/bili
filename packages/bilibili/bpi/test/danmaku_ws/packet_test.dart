import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  group('WsPacket', () {
    test('encode heartbeat produces 16-byte packet with op=2', () {
      final packet = WsPacket(
        packetLen: 16,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.heartbeat.code,
        sequence: 1,
      );
      final bytes = packet.encode();
      expect(bytes.length, 16);
      // packetLen (UInt32 BE) = 16
      expect(bytes[3], 16);
      // operation (UInt32 BE) = 2
      expect(bytes[11], 2);
    });

    test('encode auth with JSON body produces correct packet', () {
      final body = [104, 101, 108, 108, 111]; // "hello"
      final packet = WsPacket(
        packetLen: 16 + body.length,
        headerLen: 16,
        protocolVersion: 1,
        operation: WsOperation.auth.code,
        sequence: 1,
        body: body,
      );
      final bytes = packet.encode();
      expect(bytes.length, 21);
      expect(bytes[3], 21); // packetLen
      expect(bytes[11], 7); // operation = auth
      expect(bytes[7], 1); // protocolVersion
      expect(bytes.sublist(16), body);
    });

    test('decode round-trip preserves all fields', () {
      final body = [1, 2, 3, 4, 5];
      final original = WsPacket(
        packetLen: 21,
        headerLen: 16,
        protocolVersion: 2,
        operation: WsOperation.message.code,
        sequence: 42,
        body: body,
      );
      final decoded = WsPacket.decode(original.encode());
      expect(decoded.packetLen, 21);
      expect(decoded.headerLen, 16);
      expect(decoded.protocolVersion, 2);
      expect(decoded.operation, WsOperation.message.code);
      expect(decoded.sequence, 42);
      expect(decoded.body, body);
    });

    test('split splits two concatenated packets', () {
      final p1 = WsPacket(
        packetLen: 16,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.heartbeat.code,
        sequence: 1,
      );
      final p2 = WsPacket(
        packetLen: 16,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.heartbeatReply.code,
        sequence: 1,
      );
      final combined = [...p1.encode(), ...p2.encode()];
      final (packet, rest) = WsPacket.split(combined);
      expect(packet.operation, WsOperation.heartbeat.code);
      expect(rest, p2.encode());
    });

    test('split throws on incomplete packet', () {
      final p1 = WsPacket(
        packetLen: 20,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.message.code,
        sequence: 1,
        body: [1, 2, 3, 4],
      );
      final partial = p1.encode().sublist(0, 18);
      expect(() => WsPacket.split(partial), throwsA(isA<FormatException>()));
    });

    test('decode with body extracts body correctly', () {
      final body = [104, 105]; // "hi"
      final packet = WsPacket(
        packetLen: 18,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.message.code,
        sequence: 1,
        body: body,
      );
      final decoded = WsPacket.decode(packet.encode());
      expect(decoded.body, body);
    });

    test('decode throws on fewer than 16 bytes', () {
      expect(() => WsPacket.decode([1, 2, 3]), throwsA(isA<FormatException>()));
    });

    test('encode heartbeat with empty body has packetLen=16', () {
      final packet = WsPacket(
        packetLen: 16,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.heartbeat.code,
        sequence: 1,
      );
      expect(packet.encode().length, 16);
    });

    test('decode preserves packetLen when body is shorter than declared', () {
      // encode() recomputes packetLen = 16 + body.length, so a 2-byte
      // body yields packetLen=18 regardless of the constructor value.
      final packet = WsPacket(
        packetLen: 20,
        headerLen: 16,
        protocolVersion: 0,
        operation: WsOperation.message.code,
        sequence: 1,
        body: [1, 2],
      );
      final decoded = WsPacket.decode(packet.encode());
      expect(decoded.packetLen, 18);
      expect(decoded.body, [1, 2]);
    });
  });
}
