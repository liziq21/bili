import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
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
    MediaPlaybackController? controller,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: VideoPlayer(controller: controller),
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

  group('queue control bar', () {
    testWidgets(
      'next button drives controller.next and previous button drives controller.previous',
      (tester) async {
        final fake = _FakePlatformPlayer();
        final controller = MediaPlaybackController(fake);

        final bloc = VideoBloc(repository: _NoStreamRepository());
        await pumpPlayer(tester, bloc: bloc, controller: controller);

        // 无 stream、无 streamError：画面区是 loading，但注入了外部 controller，
        // 控制条照常渲染。初始无队列事件：两个按钮禁用。
        expect(find.byTooltip('下一首'), findsOneWidget);
        expect(find.byTooltip('上一首'), findsOneWidget);

        // 走真实入口造队列：open() 同时订阅流并推首个 queue 状态事件。
        await controller.openQueue([
          MediaStream(videoUrl: 'https://example.com/1.m4s'),
          MediaStream(videoUrl: 'https://example.com/2.m4s'),
        ]);
        await tester.pump();

        await tester.tap(find.byTooltip('下一首'));
        await tester.pump();
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, isEmpty);

        await tester.tap(find.byTooltip('上一首'));
        await tester.pump();
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, hasLength(1));

        addTearDown(controller.dispose);
        addTearDown(bloc.close);
      },
    );
  });
}

/// 详情与地址都不可用的仓库：画面区停在 loading，但允许外部注入 controller。
class _NoStreamRepository() implements VideoDetailRepository {
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
    return Completer<Result<MediaStream>>().future;
  }
}

/// 只实现被观察的那几个流的假播放器，与
/// `media_playback_controller_test.dart` 里的形态一致，此处只保留队列测试
/// 需要的 next/previous 调用记录与 playlist 事件注入。
// ignore_for_file: close_sinks
class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  this {
    stream = PlayerStream(
      _playlist.stream,
      _playing.stream,
      _completed.stream,
      _position.stream,
      _duration.stream,
      _volume.stream,
      _rate.stream,
      _pitch.stream,
      _buffering.stream,
      _bufferingPercentage.stream,
      _buffer.stream,
      _playlistMode.stream,
      _shuffle.stream,
      _audioParams.stream,
      _videoParams.stream,
      _audioBitrate.stream,
      _audioDevice.stream,
      _audioDevices.stream,
      _track.stream,
      _tracks.stream,
      _width.stream,
      _height.stream,
      _subtitle.stream,
      _log.stream,
      _error.stream,
    );
  }

  final _playlist = StreamController<Playlist>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _pitch = StreamController<double>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _buffer = StreamController<Duration>.broadcast();
  final _bufferingPercentage = StreamController<double>.broadcast();
  final _playlistMode = StreamController<PlaylistMode>.broadcast();
  final _shuffle = StreamController<bool>.broadcast();
  final _audioParams = StreamController<AudioParams>.broadcast();
  final _videoParams = StreamController<VideoParams>.broadcast();
  final _audioBitrate = StreamController<double?>.broadcast();
  final _audioDevice = StreamController<AudioDevice>.broadcast();
  final _audioDevices = StreamController<List<AudioDevice>>.broadcast();
  final _track = StreamController<Track>.broadcast();
  final _tracks = StreamController<Tracks>.broadcast();
  final _width = StreamController<int?>.broadcast();
  final _height = StreamController<int?>.broadcast();
  final _subtitle = StreamController<List<String>>.broadcast();
  final _log = StreamController<PlayerLog>.broadcast();
  final _error = StreamController<String>.broadcast();

  @override
  late PlayerState state;

  @override
  late PlayerStream stream;

  /// next() 的调用计数。
  final List<int> nextCalls = [];

  /// previous() 的调用计数。
  final List<int> previousCalls = [];

  @override
  Future<void> next() async => nextCalls.add(0);

  @override
  Future<void> previous() async => previousCalls.add(0);

  @override
  Future<void> jump(int index) async {}

  @override
  Future<void> add(Media media) async {}

  @override
  Future<void> remove(int index) async {}

  @override
  Future<void> move(int from, int to) async {}

  @override
  Future<void> setPlaylistMode(PlaylistMode mode) async {}

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    if (playable is Playlist) {
      _playlist.add(playable);
    }
  }

  @override
  Future<void> dispose() async {}
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

/// 详情接口返回错误：播放队列 UI 已接入，此用例只关心地址通道。
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
