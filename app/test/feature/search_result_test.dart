import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:app/feature/search/search_result.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';

// ignore_for_file: use_primary_constructors

class FakeEmptySearchContentsRepository
    implements SearchContentsRepository<VideoModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    return Result.ok(Page<VideoModel>(data: [], number: 1, totalPages: 1));
  }
}

void main() {
  testWidgets('SearchResult renders empty state when search returns no items', (
    tester,
  ) async {
    final repository = FakeEmptySearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SearchResultBloc<VideoModel>>.value(
          value: bloc,
          child: Scaffold(
            body: SearchResult<VideoModel>(
              itemBuilder: (context, item, index) => Text(item.title),
            ),
          ),
        ),
      ),
    );

    bloc.add(const FetchNextPage());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    expect(find.text('未找到内容'), findsOneWidget);
  });
}
