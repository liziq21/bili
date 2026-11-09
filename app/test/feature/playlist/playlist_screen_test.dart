import 'dart:async';

import 'package:app/data/repository/playlist_content_repository.dart';
import 'package:app/feature/playlist/playlist_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart' as data;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

/// 记录调用参数并按需返回固定内容的 fake 仓库。
final class _FakePlaylistContentRepository({
  required final Result<data.Page<data.PlaylistDetail>, Exception> pageResult,
  final data.FullPlaylistFetchResult<data.VideoModel>? fullResult,
  final Completer<data.FullPlaylistFetchResult<data.VideoModel>>? fullCompleter,
}) implements PlaylistContentRepository {
  String? requestedPlaylistId;
  int? requestedPage;
  int fetchAllCallCount = 0;

  @override
  Future<Result<data.Page<data.PlaylistDetail>, Exception>>
  fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedPlaylistId = playlistId;
    requestedPage = page;
    return pageResult;
  }

  @override
  Future<data.FullPlaylistFetchResult<data.VideoModel>> fetchAll({
    required String playlistId,
    int pageSize = 30,
    int startPage = 1,
    void Function(int fetchedCount)? onProgress,
  }) {
    fetchAllCallCount++;
    requestedPlaylistId = playlistId;
    final completer = fullCompleter;
    if (completer != null) return completer.future;
    return Future.value(
      fullResult ??
          const data.FullPlaylistFetchResult<data.VideoModel>(
            items: <data.VideoModel>[],
            completed: true,
            nextPage: null,
          ),
    );
  }
}

const _detail = data.PlaylistDetail(
  id: '2:12345',
  title: 'Flutter 入门列表',
  description: 'Flutter 播放列表页',
  creatorName: 'CodeCraft',
  totalCount: 3,
  items: [
    data.VideoModel(
      id: 'BV1',
      title: '第一个视频',
      url: 'https://www.bilibili.com/video/BV1',
    ),
    data.VideoModel(
      id: 'BV2',
      title: '列表样本视频',
      url: 'https://www.bilibili.com/video/BV2',
    ),
  ],
);

Result<data.Page<data.PlaylistDetail>, Exception> _successDetail() =>
    Result.success(
      data.Page<data.PlaylistDetail>(number: 1, totalPages: 2, data: [_detail]),
    );

Widget _screenUnder(
  PlaylistContentRepository repository, {
  VoidCallback? onBack,
}) {
  return RepositoryProvider<PlaylistContentRepository>.value(
    value: repository,
    child: MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlaylistScreen(playlistId: '2:12345', onBackClick: onBack),
    ),
  );
}

/// 播放列表条目用 [VideoCard] 渲染，其 16:9 封面按宽度取高；测试窗口给足高度，
/// 避免卡片被固定高度裁剪。
Future<void> _useTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump();
}

/// 读取当前 material_ui 树上的本地化实例，避免与界面展示所用的 locale 脱钩。
AppLocalizations _l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PlaylistScreen)))!;

void main() {
  testWidgets('renders the playlist header and items', (tester) async {
    await _useTallSurface(tester);
    final repository = _FakePlaylistContentRepository(
      pageResult: _successDetail(),
    );
    await tester.pumpWidget(_screenUnder(repository));
    await tester.pumpAndSettle();
    final l10n = _l10nOf(tester);

    expect(repository.requestedPlaylistId, '2:12345');
    expect(find.text(l10n.playlistTitle), findsOneWidget);
    expect(find.text('Flutter 入门列表'), findsOneWidget);
    expect(find.text('Flutter 播放列表页'), findsOneWidget);
    expect(find.textContaining(l10n.playlistItemCount('3')), findsOneWidget);
    expect(find.text('第一个视频'), findsOneWidget);
    expect(find.text('列表样本视频'), findsOneWidget);
    expect(find.text(l10n.playlistFetchAll), findsOneWidget);
  });

  testWidgets('shows the description placeholder when the playlist has none', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakePlaylistContentRepository(
      pageResult: Result.success(
        data.Page<data.PlaylistDetail>(
          number: 1,
          totalPages: 1,
          data: [
            data.PlaylistDetail(
              id: '2:12345',
              title: '无播放列表',
              items: [
                data.VideoModel(
                  id: 'BV1',
                  title: '单条样本视频',
                  url: 'https://www.bilibili.com/video/BV1',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_screenUnder(repository));
    await tester.pumpAndSettle();
    final l10n = _l10nOf(tester);

    expect(find.text(l10n.playlistDescriptionUnavailable), findsOneWidget);
  });

  testWidgets('triggers back callback when back button pressed', (
    tester,
  ) async {
    await _useTallSurface(tester);
    var backPressed = false;
    final repository = _FakePlaylistContentRepository(
      pageResult: _successDetail(),
    );

    await tester.pumpWidget(
      _screenUnder(repository, onBack: () => backPressed = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(backPressed, isTrue);
  });

  testWidgets('renders the error view and retries on press', (tester) async {
    await _useTallSurface(tester);
    final repository = _FakePlaylistContentRepository(
      pageResult: Result.error(Exception('failed')),
    );
    await tester.pumpWidget(_screenUnder(repository));
    await tester.pumpAndSettle();
    final l10n = _l10nOf(tester);

    expect(find.text(l10n.loadFailedRetryLater), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('fetches every page on tap and shows the item count', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final completer =
        Completer<data.FullPlaylistFetchResult<data.VideoModel>>();
    final repository = _FakePlaylistContentRepository(
      pageResult: _successDetail(),
      fullCompleter: completer,
    );
    await tester.pumpWidget(_screenUnder(repository));
    await tester.pumpAndSettle();
    final l10n = _l10nOf(tester);

    await tester.tap(find.text(l10n.playlistFetchAll));
    await tester.pump();

    expect(repository.fetchAllCallCount, 1);
    expect(find.text(l10n.playlistFetchAllProgress('2')), findsOneWidget);

    completer.complete(
      const data.FullPlaylistFetchResult<data.VideoModel>(
        items: [
          data.VideoModel(
            id: 'BV1',
            title: '第一个视频',
            url: 'https://www.bilibili.com/video/BV1',
          ),
          data.VideoModel(
            id: 'BV2',
            title: '列表样本视频',
            url: 'https://www.bilibili.com/video/BV2',
          ),
          data.VideoModel(
            id: 'BV3',
            title: '第三个视频',
            url: 'https://www.bilibili.com/video/BV3',
          ),
        ],
        completed: true,
        nextPage: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.playlistFetchAllDone('3')), findsOneWidget);
    expect(find.text('第三个视频'), findsOneWidget);
  });

  testWidgets('reports a partial fetch when the full fetch stops early', (
    tester,
  ) async {
    await _useTallSurface(tester);
    final repository = _FakePlaylistContentRepository(
      pageResult: _successDetail(),
      fullResult: const data.FullPlaylistFetchResult<data.VideoModel>(
        items: [
          data.VideoModel(
            id: 'BV1',
            title: '第一个视频',
            url: 'https://www.bilibili.com/video/BV1',
          ),
        ],
        completed: false,
        nextPage: 2,
        error: 'interrupted',
      ),
    );
    await tester.pumpWidget(_screenUnder(repository));
    await tester.pumpAndSettle();
    final l10n = _l10nOf(tester);

    await tester.tap(find.text(l10n.playlistFetchAll));
    await tester.pumpAndSettle();

    expect(find.text(l10n.playlistFetchAllPartial('1')), findsOneWidget);
  });
}
