import 'package:app/ui/metadata_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 测试字体里每个字形都是 1em 宽，因此 `fontSize: 10` 下每个字符正好 10dp，
/// 可以按字符数算出每一行放得下什么。
const _style = TextStyle(fontSize: 10);
const _separator = '|';

void main() {
  Future<void> pumpLine(
    WidgetTester tester, {
    required List<MetadataPart> parts,
    required double width,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: MetadataLine(
                  parts: parts,
                  separator: _separator,
                  style: _style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  RenderMetadataLine renderObject(WidgetTester tester) =>
      tester.renderObject<RenderMetadataLine>(find.byType(MetadataLine));

  String rendered(WidgetTester tester) => renderObject(tester).renderedText;

  testWidgets('joins every field in the given order when it all fits', (
    WidgetTester tester,
  ) async {
    await pumpLine(
      tester,
      width: 200,
      parts: const [
        MetadataPart('aaaa', priority: 2),
        MetadataPart('bbbbbbbb', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaa|bbbbbbbb');
  });

  testWidgets('drops the lowest-priority field first', (
    WidgetTester tester,
  ) async {
    // 40 + 10 + 80 = 130 > 100：丢掉分值最低的 'bbbbbbbb'，而不是把整串
    // 交给省略号——那样连 'aaaa' 也读不全。
    await pumpLine(
      tester,
      width: 100,
      parts: const [
        MetadataPart('aaaa', priority: 2),
        MetadataPart('bbbbbbbb', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaa');
    expect(renderObject(tester).textWasClipped, isFalse);
  });

  testWidgets('keeps dropping until the rest fits', (
    WidgetTester tester,
  ) async {
    await pumpLine(
      tester,
      width: 100,
      parts: const [
        MetadataPart('aaa', priority: 3),
        MetadataPart('bbbb', priority: 2),
        MetadataPart('ccccc', priority: 1),
      ],
    );

    // 三个字段共 3+1+4+1+5 = 14 字符 = 140 > 100；先丢 'ccccc' 得
    // 'aaa|bbbb' = 80，放得下。
    expect(rendered(tester), 'aaa|bbbb');
  });

  testWidgets('drops the later field when two fields score the same', (
    WidgetTester tester,
  ) async {
    await pumpLine(
      tester,
      width: 60,
      parts: const [
        MetadataPart('aaaa', priority: 1),
        MetadataPart('bbbb', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaa');
  });

  testWidgets('never drops the last field, ellipsising it instead', (
    WidgetTester tester,
  ) async {
    // 丢掉低分字段后仍放不下：此时只剩一个字段，省略号是唯一还能表达
    // 「这里还有内容」的手段。
    await pumpLine(
      tester,
      width: 40,
      parts: const [
        MetadataPart('aaaaaaaaaa', priority: 2),
        MetadataPart('bb', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaaaaaaaa');
    expect(renderObject(tester).textWasClipped, isTrue);
  });

  testWidgets('skips empty fields and renders nothing when all are empty', (
    WidgetTester tester,
  ) async {
    await pumpLine(
      tester,
      width: 200,
      parts: const [
        MetadataPart('', priority: 3),
        MetadataPart('aaaa', priority: 2),
        MetadataPart('', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaa');

    await pumpLine(
      tester,
      width: 200,
      parts: const [MetadataPart('', priority: 1)],
    );

    expect(rendered(tester), '');
  });

  testWidgets('drops more fields as the system font grows', (
    WidgetTester tester,
  ) async {
    const parts = [
      MetadataPart('aaaa', priority: 2),
      MetadataPart('bbbb', priority: 1),
    ];

    await pumpLine(tester, width: 100, parts: parts);
    expect(rendered(tester), 'aaaa|bbbb');

    // 1.5 倍字号下同一行需要 135dp，只剩最高分的字段放得下。
    await pumpLine(tester, width: 100, parts: parts, textScale: 1.5);
    expect(rendered(tester), 'aaaa');
  });

  testWidgets('screen readers get every field, even the dropped ones', (
    WidgetTester tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpLine(
      tester,
      width: 100,
      parts: const [
        MetadataPart('aaaa', priority: 2),
        MetadataPart('bbbbbbbb', priority: 1),
      ],
    );

    expect(rendered(tester), 'aaaa');
    // 丢字段只是宽度不够时的视觉取舍，语义标签保留完整的一串。
    final node = tester.getSemantics(find.byType(MetadataLine));
    expect(node.getSemanticsData().label, 'aaaa|bbbbbbbb');
    handle.dispose();
  });

  testWidgets('can be measured by intrinsic-size containers', (
    WidgetTester tester,
  ) async {
    // 卡片也会出现在按固有尺寸测量的容器里（`Table`、`IntrinsicHeight`）。
    // 用 `LayoutBuilder` 取宽度的实现会在这里直接抛异常。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    const MetadataLine(
                      parts: [
                        MetadataPart('aaaa', priority: 2),
                        MetadataPart('bbbb', priority: 1),
                      ],
                      separator: _separator,
                      style: _style,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(rendered(tester), 'aaaa|bbbb');
  });
}
