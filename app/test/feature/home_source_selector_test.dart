import 'package:app/feature/home/widgets/home_source_selector.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class const FakeMediaSource(
  @override final String id,
  @override final String name,
) implements MediaSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeSourceSelector renders with tooltip and semantics', (
    WidgetTester tester,
  ) async {
    final sources = [
      MediaSourceDefinition(
        id: 'bilibili',
        name: 'Bilibili',
        create: () => const FakeMediaSource('bilibili', 'Bilibili'),
      ),
      MediaSourceDefinition(
        id: 'youtube',
        name: 'YouTube',
        create: () => const FakeMediaSource('youtube', 'YouTube'),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: HomeSourceSelector(
              sources: sources,
              activeSourceId: 'bilibili',
            ),
          ),
        ),
      ),
    );

    // Verify Dropdown button displays active source name
    expect(find.text('Bilibili'), findsOneWidget);

    // Verify Tooltip presence
    expect(find.byType(Tooltip), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, '切换数据源');

    // Verify Semantics
    final semanticsFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '切换数据源' &&
          widget.properties.value == 'Bilibili' &&
          widget.properties.hint == '切换视频与媒体数据源',
    );
    expect(semanticsFinder, findsOneWidget);
  });
}
