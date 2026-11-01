import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/video_screen.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('video detail page exposes a page back button', (tester) async {
    var backPressed = false;

    // 提供足够的窗口大小，避免 PlaybackQueueSheet 在极小约束下溢出。
    // 同时设置 tester.view 并显式包裹 MediaQuery，确保 material_ui MaterialApp 继承正确的视口尺寸。
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600), devicePixelRatio: 1.0),
        child: Provider<MediaSource>.value(
          value: const _TestMediaSource(),
          child: RepositoryProvider<VideoDetailRepository>.value(
            value: const _FailingVideoDetailRepository(),
            child: MaterialApp(
              home: VideoScreen(onBackClick: () => backPressed = true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backPressed, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class const _TestMediaSource() extends MediaSource {
  @override
  String get id => 'test';

  @override
  String get name => 'Test';
}

class const _FailingVideoDetailRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.error(Exception('unused'));
}
