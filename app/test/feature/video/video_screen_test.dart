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

    // 设置测试视口大小，避免 PlaybackQueueSheet 在极小约束下溢出。
    // 先 pump 一次空 widget 初始化视图，再设置 physicalSize，
    // 然后 pump 实际内容。MaterialApp 会创建自己的 MediaQuery，
    // 所以 tester.view.physicalSize 必须在 pumpWidget 之前生效。
    // 额外用 SizedBox 约束返回的 widget，防止 MaterialApp 的 MediaQuery 被忽略。
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Provider<MediaSource>.value(
        value: const _TestMediaSource(),
        child: RepositoryProvider<VideoDetailRepository>.value(
          value: const _FailingVideoDetailRepository(),
          child: MaterialApp(
            home: SizedBox(
              width: 800,
              height: 600,
              child: VideoScreen(onBackClick: () => backPressed = true),
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
