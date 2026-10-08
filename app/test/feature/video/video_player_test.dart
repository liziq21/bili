import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

void main() {
  /// 两个用例都不创建 `_VideoSurface`（loading 与 error 分支在渲染管线外
  /// 返回），故不注入 [MediaPlaybackController]。
  ///
  /// stream 到位后进入 `_VideoSurface`、由 `Video` 组件渲染画面的路径不在此
  /// 覆盖：`VideoController` 构造会异步创建平台纹理，测试环境无 libmpv，该
  /// 创建经 `completeError` 兜底但 `Future.error` 仍冒出测试 zone，且 `Video`
  /// 组件本身只渲染空盒子（`notifier == null` 时返回 `SizedBox.shrink()`）。
  /// 该路径的地址拼装与转交由 `media_playback_controller_test.dart` 覆盖。
  Future<void> pumpPlayer(
    WidgetTester tester, {
    required VideoBloc bloc,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: const VideoPlayer(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the loading view before the stream resolves', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _HangingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);

    addTearDown(bloc.close);
  });

  testWidgets('renders the stream error inside the player area', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _FailingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);
    bloc.add(const LoadMediaStream('BV123'));
    // 不用 pumpAndSettle：_HangingStreamRepository 的 future 永不完成，
    // settle 会等到超时。这里地址失败是同步路径，几帧足够。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('播放失败'), findsOneWidget);
    // 关键判据：错误只出现在播放器区域内，不把整页顶掉。
    expect(find.byType(CircularProgressIndicator), findsNothing);

    addTearDown(bloc.close);
  });
}

/// 地址请求永不返回，用于把控件留在 loading 态。
class _HangingStreamRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async {
    // 故意不完成：loading 态就是「地址还没到」。
    return Completer<Result<MediaStream>>().future;
  }
}

/// 详情接口返回错误：播放队列 UI 尚未接入，测试只关心地址通道。
class _FailingStreamRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async => Result.error(Exception('签名过期'));
}
