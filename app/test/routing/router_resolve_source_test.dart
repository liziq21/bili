import 'package:app/providers/media_sources_provider.dart';
import 'package:app/providers/service_source_providers.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _FakeSource(@override final String id) extends MediaSource {
  @override
  String get name => id;
}

void main() {
  testWidgets('known source IDs create a route-scoped source', (tester) async {
    Object? source;
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: defaultMediaSourceCatalog,
        child: MaterialApp(
          home: ServiceSourceProviders(
            source: 'bilibili',
            child: Builder(
              builder: (context) {
                source = context.read<MediaSource>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(source, isA<MediaSource>());
  });

  testWidgets('unknown source IDs fail before the child is built', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: defaultMediaSourceCatalog,
        child: const MaterialApp(
          home: ServiceSourceProviders(
            source: 'unknown',
            child: Text('should not render'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isArgumentError);
    expect(find.text('should not render'), findsNothing);
  });

  testWidgets('an empty catalog is a valid state', (tester) async {
    final catalog = MediaSourceCatalog(const []);
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: catalog,
        child: const MaterialApp(home: Text('no source')),
      ),
    );

    expect(find.text('no source'), findsOneWidget);
    expect(catalog.resolvePersisted(null), isNull);
  });

  testWidgets('a custom source can be created from the catalog', (
    tester,
  ) async {
    final source = _FakeSource('custom');
    final catalog = MediaSourceCatalog([
      MediaSourceDefinition(id: 'custom', name: 'Custom', create: () => source),
    ]);
    Object? provided;

    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: catalog,
        child: MaterialApp(
          home: ServiceSourceProviders(
            source: 'custom',
            child: Builder(
              builder: (context) {
                provided = context.read<MediaSource>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(identical(provided, source), isTrue);
  });
}
