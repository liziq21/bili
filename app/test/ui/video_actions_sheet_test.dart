import 'package:app/data/repository/local_library_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/ui/video_actions_sheet.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppDatabase database;
  late LocalLibraryRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = LocalLibraryRepository(dao: database.localLibraryDao);
  });

  tearDown(() => database.close());

  const video = VideoModel(
    id: 'video-1',
    title: 'Video title',
    url: 'https://example.com/video-1',
    creatorProfileName: 'Creator',
  );

  void testSheet(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }

  // Provider 放在 MaterialApp 之上：bottom sheet 挂在 Navigator 的 overlay 里，
  // 只包在 home 下面就读不到了（正式 App 也是这么放的）。
  Widget app() => RepositoryProvider<LocalLibraryRepository>.value(
    value: repository,
    child: MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => VideoActionsSheet.show(
              context,
              sourceId: 'bilibili',
              video: video,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  /// 帧推进之外还要让真实的数据库 I/O 跑完：`pump` 只清微任务，drift 的查询
  /// 完成得靠事件循环，否则断言可能早于写入完成。
  Future<void> settle(WidgetTester tester) async {
    for (var index = 0; index < 8; index++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testSheet('saves the video to the local watch later list', (tester) async {
    await tester.pumpWidget(app());
    await pumpSheet(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ListTile).first),
    )!;
    expect(find.text(l10n.saveToWatchLater), findsOneWidget);

    await tester.tap(find.text(l10n.saveToWatchLater));
    await settle(tester);

    expect(await repository.isInWatchLater('bilibili', 'video-1'), isTrue);
    expect(find.text(l10n.savedToWatchLater), findsOneWidget);
    // 保存后面板自己关掉，不用用户再点一次。
    expect(find.byType(VideoActionsSheet), findsNothing);
  });

  testSheet('offers removal when the video is already saved', (tester) async {
    await repository.setWatchLater(
      sourceId: 'bilibili',
      video: video,
      saved: true,
    );
    await tester.pumpWidget(app());
    await pumpSheet(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ListTile).first),
    )!;
    expect(find.text(l10n.removeFromWatchLater), findsOneWidget);

    await tester.tap(find.text(l10n.removeFromWatchLater));
    await settle(tester);

    expect(await repository.isInWatchLater('bilibili', 'video-1'), isFalse);
    expect(find.text(l10n.removedFromWatchLater), findsOneWidget);
  });

  testSheet('reports a failed read instead of offering save', (tester) async {
    await database.customStatement('DROP TABLE local_watch_later');
    await tester.pumpWidget(app());
    await pumpSheet(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ListTile).first),
    )!;
    expect(find.text(l10n.loadFailedRetryLater), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
    expect(find.text(l10n.saveToWatchLater), findsNothing);
    expect(find.text(l10n.removeFromWatchLater), findsNothing);
  });

  testSheet('keeps the sheet open and reports a failed write', (tester) async {
    await tester.pumpWidget(app());
    await pumpSheet(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ListTile).first),
    )!;
    await database.customStatement('DROP TABLE local_watch_later');

    await tester.tap(find.text(l10n.saveToWatchLater));
    await settle(tester);

    expect(find.byType(VideoActionsSheet), findsOneWidget);
    expect(find.textContaining(l10n.operationFailed('')), findsOneWidget);
  });
}
