import 'package:app/data/repository/creator_profile_repository.dart';
import 'package:app/feature/space/space_screen.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

class _FakeCreatorProfileRepository(var Result<CreatorProfile> result)
    implements CreatorProfileRepository {
  String? requestedId;

  @override
  Future<Result<CreatorProfile>> getProfile(String id) async {
    requestedId = id;
    return result;
  }
}

void main() {
  testWidgets('renders the creator profile header from repository data', (
    tester,
  ) async {
    const profile = CreatorProfile(
      id: 'creator-1',
      name: 'CodeCraft',
      description: 'Builds useful videos',
      subscribers: 12000,
      videos: 42,
    );
    final repository = _FakeCreatorProfileRepository(Result.ok(profile));
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedId, 'creator-1');
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byTooltip('CodeCraft'), findsOneWidget);
    expect(find.text('CodeCraft'), findsOneWidget);
    expect(find.text('Builds useful videos'), findsOneWidget);
    expect(find.text(l10n.creatorLabel('@creator-1')), findsOneWidget);
    expect(
      find.text(l10n.subscribersCount(l10n.countCompactWan('1.2'))),
      findsOneWidget,
    );
    expect(find.text(l10n.videosCount('42')), findsOneWidget);

    final expectedLabel = [
      'CodeCraft',
      l10n.creatorLabel('@creator-1'),
      'Builds useful videos',
      l10n.subscribersCount(l10n.countCompactWan('1.2')),
      l10n.videosCount('42'),
    ].join(l10n.commaSeparator);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.container == true &&
            widget.excludeSemantics == true &&
            widget.properties.label == expectedLabel,
      ),
      findsOneWidget,
    );
  });

  testWidgets('triggers back callback when back button pressed', (
    tester,
  ) async {
    const profile = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final repository = _FakeCreatorProfileRepository(Result.ok(profile));
    var backPressed = false;

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: MaterialApp(
          home: SpaceScreen(
            mid: 'creator-1',
            onBackClick: () => backPressed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(backPressed, isTrue);
  });

  testWidgets('renders error view and triggers retry when pressed', (
    tester,
  ) async {
    final repository = _FakeCreatorProfileRepository(
      Result.error(Exception('Failed to load')),
    );
    final l10n = AppLocalizationsZh();

    await tester.pumpWidget(
      RepositoryProvider<CreatorProfileRepository>.value(
        value: repository,
        child: const MaterialApp(home: SpaceScreen(mid: 'creator-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.loadFailedRetryLater), findsOneWidget);
    final retryButton = find.text(l10n.retry);
    expect(retryButton, findsOneWidget);

    repository.result = Result.ok(
      const CreatorProfile(id: 'creator-1', name: 'CodeCraft'),
    );

    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.text('CodeCraft'), findsOneWidget);
  });
}
