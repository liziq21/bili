import 'dart:async';

import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/feature/home/bloc/home_bloc.dart';
import 'package:app/feature/home/widgets/home_source_selector.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_en.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

class const FakeMediaSource(
  @override final String id,
  @override final String name,
) extends MediaSource;

class RecordingUserDataRepository() implements UserDataRepository {
  final _controller = StreamController<UserData>.broadcast();
  String? lastSourceId;

  @override
  Stream<UserData> get data => _controller.stream;

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async {
    lastSourceId = sourceId;
    return const Result.success(null);
  }

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(
    bool useDynamicColor,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setFontScale(double fontScale) async =>
      const Result.success(null);

  void dispose() => _controller.close();
}

void main() {
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

  Widget buildSelector(HomeBloc bloc) => BlocProvider<HomeBloc>.value(
    value: bloc,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('renders with tooltip and semantics', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final l10n = AppLocalizationsEn();
    final repository = RecordingUserDataRepository();
    final bloc = HomeBloc(
      userDataRepository: repository,
      preferences: null,
      source: const FakeMediaSource('bilibili', 'Bilibili'),
    );
    addTearDown(() {
      bloc.close();
      repository.dispose();
    });

    await tester.pumpWidget(buildSelector(bloc));

    expect(find.text('Bilibili'), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, l10n.switchDataSource);

    final data = tester
        .getSemantics(find.byType(DropdownButton<String>))
        .getSemanticsData();
    expect(data.label, contains(l10n.switchDataSource));
    expect(data.label, contains('Bilibili'));
    expect(data.hint, l10n.switchVideoMediaSource);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    semantics.dispose();
  });

  testWidgets('opens the menu and switches source from the screen reader', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = RecordingUserDataRepository();
    final bloc = HomeBloc(
      userDataRepository: repository,
      preferences: null,
      source: const FakeMediaSource('bilibili', 'Bilibili'),
    );
    addTearDown(() {
      bloc.close();
      repository.dispose();
    });

    await tester.pumpWidget(buildSelector(bloc));

    final node = tester.getSemantics(find.byType(DropdownButton<String>));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    // Select the entry the same way a screen reader does, so a menu item that
    // lost its tap action would fail this test too.
    final item = tester.getSemantics(find.text('YouTube').last);
    expect(item.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    item.owner!.performAction(item.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(repository.lastSourceId, 'youtube');
    semantics.dispose();
  });
}
