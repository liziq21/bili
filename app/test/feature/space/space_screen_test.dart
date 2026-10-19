import 'package:app/data/repository/creator_profile_repository.dart';
import 'package:app/feature/space/space_screen.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

class _FakeCreatorProfileRepository(final CreatorProfile profile)
    implements CreatorProfileRepository {
  String? requestedId;

  @override
  Future<Result<CreatorProfile>> getProfile(String id) async {
    requestedId = id;
    return Result.ok(profile);
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
    final repository = _FakeCreatorProfileRepository(profile);
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
    expect(find.text('CodeCraft'), findsOneWidget);
    expect(find.text('Builds useful videos'), findsOneWidget);
    expect(find.text(l10n.creatorLabel('@creator-1')), findsOneWidget);
    expect(
      find.text(l10n.subscribersCount(l10n.countCompactWan('1.2'))),
      findsOneWidget,
    );
    expect(find.text(l10n.videosCount('42')), findsOneWidget);
  });
}
