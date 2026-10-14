import 'package:app/database/local_media_key.dart';
import 'package:test/test.dart';

void main() {
  test('keeps media identities isolated by source', () {
    const bilibili = LocalMediaKey('bilibili', 'same-id');
    const youtube = LocalMediaKey('youtube', 'same-id');

    expect(bilibili, isNot(equals(youtube)));
    expect(bilibili, equals(const LocalMediaKey('bilibili', 'same-id')));
  });
}
