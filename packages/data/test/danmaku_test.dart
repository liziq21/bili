import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  test('DanmakuComment keeps source-neutral timing and placement data', () {
    const comment = DanmakuComment(
      startTime: Duration(seconds: 2),
      mode: DanmakuMode.top,
      fontSize: 25,
      colorArgb: 0xFFFFFFFF,
      content: 'hello',
      rowId: 7,
    );

    expect(comment.startTime, const Duration(seconds: 2));
    expect(comment.mode, DanmakuMode.top);
    expect(comment.content, 'hello');
    expect(comment.rowId, 7);
  });
}
