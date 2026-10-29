import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:app/feature/search/search_result_screen.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';

class const FakeVideoSearchRepository({final List<VideoModel> items = const []})
    implements SearchContentsRepository<VideoModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<VideoModel>(data: items, number: 1, totalPages: 1),
    );
  }
}

class TrackingFailingVideoSearchRepository()
    implements SearchContentsRepository<VideoModel> {
  int searchCallCount = 0;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    searchCallCount++;
    return Result.error(Exception('Search error'));
  }
}

class const FakeCreatorProfileSearchRepository()
    implements SearchContentsRepository<CreatorProfile> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<CreatorProfile>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<CreatorProfile>(data: [], number: 1, totalPages: 1),
    );
  }
}

void main() {
  testWidgets(
    'SearchResultScreen renders fallback tab headers without raw identifier key',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // English fallback labels should be rendered when AppLocalizations is null
      expect(find.text('Creators'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('creatorProfile'), findsNothing);
    },
  );

  testWidgets(
    'SearchResultScreen allows switching tabs between creator profiles and videos',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      expect(find.text('Videos'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchResultScreen renders error icon, message, and retry button on search error',
    (tester) async {
      final videoRepo = TrackingFailingVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      // Initial fetch
      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Video tab
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Load failed. Please try again later.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify search repository was called again for retry
      expect(videoRepo.searchCallCount, 2);
    },
  );

  testWidgets(
    'SearchResultScreen renders empty indicator when search returns no items',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository(items: []);
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('Nothing found'), findsOneWidget);
    },
  );
}
