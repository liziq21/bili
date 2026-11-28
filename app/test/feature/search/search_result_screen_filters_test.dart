import 'dart:convert';

import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/design/design.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:app/feature/search/search_result_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:youtube/youtube.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  testWidgets('renders a live tab and navigates with the room id', (
    tester,
  ) async {
    final videoRepo = _VideoSearchRepository();
    final liveRepo = _LiveSearchRepository();
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: videoRepo,
      query: 'flutter',
    );
    final liveBloc = SearchResultBloc<LiveRoomModel>(
      searchContentsRepository: liveRepo,
      query: 'flutter',
    );
    addTearDown(videoBloc.close);
    addTearDown(liveBloc.close);

    String? navigatedRoomId;
    await tester.pumpWidget(
      _testApp(
        MultiProvider(
          providers: [
            BlocProvider<SearchResultBloc<VideoModel>>.value(value: videoBloc),
            BlocProvider<SearchResultBloc<LiveRoomModel>>.value(
              value: liveBloc,
            ),
          ],
          child: SearchResultScreen(
            query: 'flutter',
            onLive: (roomId) => navigatedRoomId = roomId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('直播'));
    await tester.pumpAndSettle();

    expect(find.text('Live room title'), findsOneWidget);
    await tester.tap(find.text('Live room title'));
    await tester.pumpAndSettle();

    expect(navigatedRoomId, '42');
  });

  testWidgets('wide live results stop at four columns instead of five', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: _VideoSearchRepository(),
      query: 'flutter',
    );
    final liveBloc = SearchResultBloc<LiveRoomModel>(
      searchContentsRepository: _LiveSearchRepository(),
      query: 'flutter',
    );
    addTearDown(videoBloc.close);
    addTearDown(liveBloc.close);

    await tester.pumpWidget(
      _testApp(
        MultiProvider(
          providers: [
            BlocProvider<SearchResultBloc<VideoModel>>.value(value: videoBloc),
            BlocProvider<SearchResultBloc<LiveRoomModel>>.value(
              value: liveBloc,
            ),
          ],
          child: const SearchResultScreen(query: 'flutter'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('直播'));
    await tester.pumpAndSettle();

    // 直播卡片原来按 280px 上限排出 5 列约 245px；限到 4 列后应更宽，
    // 缩略图才有高度可以铺满单元格。
    final card = find
        .ancestor(
          of: find.text('Live room title'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.getSize(card).width, greaterThan(280));
  });

  testWidgets('applies and persists the selected filter and sort', (
    tester,
  ) async {
    final videoRepo = _VideoSearchRepository();
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: videoRepo,
      query: 'flutter',
    );
    addTearDown(videoBloc.close);

    await tester.pumpWidget(
      _testApp(
        MultiProvider(
          providers: [
            Provider<PreferencesDataSource>.value(value: preferences),
            BlocProvider<SearchResultBloc<VideoModel>>.value(value: videoBloc),
          ],
          child: SearchResultScreen(query: 'flutter', source: 'bilibili'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-30分钟'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(
      (videoRepo.queries.last.filters.single as SingleFilterGroup).selection,
      VideoDurationFilterOption.tenTo30Minutes,
    );

    await tester.tap(find.byType(DropdownButton<SortOption>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最新发布').last);
    await tester.pumpAndSettle();

    expect(videoRepo.queries.last.sortOption, PhotoOrVideoSearchSort.pubdate);

    final stored = await preferences.get(PreferencesKey.searchFilters);
    final raw = switch (stored) {
      Success(:final success) => success,
      Error() => '',
    };
    expect(raw, contains('tenTo30Minutes'));
    expect(raw, contains('pubdate'));
    expect(jsonDecode(raw), contains('bilibili'));
  });
}

Widget _testApp(Widget child) => MaterialApp(
  localizationsDelegates: const [
    ...AppLocalizations.localizationsDelegates,
    ...GlobalMaterialLocalizations.delegates,
    YoutubeLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  home: child,
);

class _VideoSearchRepository() implements SearchContentsRepository<VideoModel> {
  final List<SearchQuery> queries = [];

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    queries.add(searchQuery);
    return Result.success(
      Page<VideoModel>(data: const [], number: 1, totalPages: 1),
    );
  }
}

class _LiveSearchRepository()
    implements SearchContentsRepository<LiveRoomModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<LiveRoomModel>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<LiveRoomModel>(
        data: const [
          LiveRoomModel(
            id: 42,
            title: 'Live room title',
            url: 'https://example.com/live/42',
            isLive: true,
          ),
        ],
        number: 1,
        totalPages: 1,
      ),
    );
  }
}
