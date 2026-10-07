import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// 只实现播放地址能力、其余返回错误的假数据源。
///
/// 播放地址与详情是两条独立能力，测试要分别覆盖「有详情无地址」「有地址
/// 无详情」两种组合，故本类刻意不实现详情接口。
class FakeMediaStreamRemoteDataSource() extends MediaStreamRemoteDataSource {
  @override
  String get sourceId => 'fake';

  /// 记录收到的 videoId，顺带验证 preferHeight 透传。
  final List<(String, int?)> requests = [];

  /// 是否对下一次请求返回失败。
  bool failNext = false;

  @override
  Future<Result<MediaStream>> getMediaStream(
    String videoId, {
    int? preferHeight,
  }) async {
    requests.add((videoId, preferHeight));
    if (failNext) {
      return Result.error(Exception('签名过期'));
    }
    return Result.ok(
      MediaStream(
        videoUrl: 'https://cdn.example.com/$videoId.m4s',
        headers: const {'Referer': 'https://www.bilibili.com'},
      ),
    );
  }
}

void main() {
  group('VideoBloc LoadMediaStream', () {
    late FakeMediaStreamRemoteDataSource fakeStreamSource;
    late AppVideoDetailRepository detailRepo;
    late VideoBloc videoBloc;

    setUp(() {
      fakeStreamSource = FakeMediaStreamRemoteDataSource();
      detailRepo = AppVideoDetailRepository(null, fakeStreamSource);
      videoBloc = VideoBloc(repository: detailRepo);
    });

    tearDown(() {
      videoBloc.close();
    });

    test(
      'emits the resolved MediaStream and keeps the detail untouched',
      () async {
        videoBloc.add(const LoadMediaStream('BV123'));

        await expectLater(
          videoBloc.stream,
          emitsInOrder([
            predicate<VideoState>(
              (state) => state.mediaStream == null && state.streamError == null,
              '先清空上次的地址错误',
            ),
            predicate<VideoState>(
              (state) =>
                  state.mediaStream != null &&
                  state.mediaStream!.videoUrl ==
                      'https://cdn.example.com/BV123.m4s',
            ),
          ]),
        );

        // 地址失败不该影响详情与错误通道：简介与评论仍可看。
        expect(videoBloc.state.error, isNull);
        expect(videoBloc.state.videoDetail, isNull);
        expect(fakeStreamSource.requests.single, ('BV123', null));
      },
    );

    test('forwards preferHeight to the data source', () async {
      fakeStreamSource.failNext = false;
      videoBloc.add(const LoadMediaStream('BV123'));

      await expectLater(
        videoBloc.stream,
        emitsInOrder([
          predicate<VideoState>((state) => state.streamError == null),
          predicate<VideoState>((state) => state.mediaStream != null),
        ]),
      );

      expect(fakeStreamSource.requests.single, ('BV123', null));
    });

    test(
      'reports the failure without touching the detail error channel',
      () async {
        fakeStreamSource.failNext = true;
        videoBloc.add(const LoadMediaStream('BV123'));

        await expectLater(
          videoBloc.stream,
          emitsInOrder([
            predicate<VideoState>((state) => state.streamError == null),
            predicate<VideoState>(
              (state) =>
                  state.mediaStream == null &&
                  state.streamError != null &&
                  state.streamError!.contains('签名过期'),
            ),
          ]),
        );

        // 关键判据：地址失败没有污染整页错误通道。
        expect(videoBloc.state.error, isNull);
        expect(videoBloc.state.isLoading, isFalse);
      },
    );

    test('mediaStream and streamError participate in equality', () {
      // 与既有 actionError 同一形态：字段不在 props 里时，两次相同失败
      // 会被判同一个状态，BlocListener 收不到第二次变化。
      const base = VideoState();

      expect(base, isNot(const VideoState(streamError: '签名过期')));
      expect(base.copyWith(mediaStream: null).mediaStream, isNull);
      // copyWith 对 streamError 是无条件赋值，不传即清空。
      expect(base.copyWith(streamError: '签名过期').streamError, '签名过期');
      expect(base.copyWith(streamError: '签名过期').copyWith().streamError, isNull);
    });
  });

  group('AppVideoDetailRepository getMediaStream', () {
    test('returns error when the source has no stream capability', () async {
      final repo = AppVideoDetailRepository(null, null);

      final result = await repo.getMediaStream('BV123');

      expect(result.isError, isTrue);
    });

    test('delegates to the stream data source', () async {
      final source = FakeMediaStreamRemoteDataSource();
      final repo = AppVideoDetailRepository(null, source);

      final result = await repo.getMediaStream('BV123', preferHeight: 720);

      expect(result.isOk, isTrue);
      expect(source.requests.single, ('BV123', 720));
    });
  });
}
