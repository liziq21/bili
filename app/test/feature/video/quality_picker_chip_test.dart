import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/quality_picker_chip.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

void main() {
  testWidgets(
    'lists same-height bitrate variants and selects the exact stream',
    (tester) async {
      final repository = _RecordingVideoDetailRepository();
      final bloc = VideoBloc(repository: repository);
      final controller = _RecordingPlaybackController();
      addTearDown(bloc.close);
      addTearDown(controller.dispose);

      bloc.add(const LoadVideoDetail('video'));
      await tester.pump();
      await tester.pump();

      final stream = MediaStream(
        videoUrl: 'https://cdn.example/high.m4s',
        height: 1080,
        bitrate: 4_000_000,
        streamId: 80,
        qualityLabel: '1080P high',
        alternatives: [
          MediaQualityOption(
            height: 1080,
            label: '1080P low',
            streamId: 81,
            bitrate: 1_000_000,
          ),
          MediaQualityOption(
            height: 720,
            label: '720P',
            streamId: 32,
            bitrate: 2_000_000,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: RepositoryProvider<VideoDetailRepository>.value(
                value: repository,
                child: QualityPickerChip(
                  controller: controller,
                  stream: stream,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('1080P high'));
      await tester.pumpAndSettle();

      // The chip remains behind the modal, so the current label is rendered
      // once in each layer.
      expect(find.text('1080P high'), findsNWidgets(2));
      expect(find.text('1080P low'), findsOneWidget);
      expect(find.text('1.0 Mbps'), findsOneWidget);
      expect(find.text('720P'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('1080P low'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(repository.lastRequest, ('video', 1080, 81));
      expect(bloc.state.mediaStream?.streamId, 81);
      expect(controller.openedStreams, isEmpty);
    },
  );
}

class _RecordingPlaybackController() extends MediaPlaybackController {
  final List<MediaStream> openedStreams = [];

  @override
  Future<void> open(
    MediaStream stream, {
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) async {
    openedStreams.add(stream);
  }
}

class _RecordingVideoDetailRepository() implements VideoDetailRepository {
  (String, int?, int?)? lastRequest;

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.success(
        VideoDetail(
          video: VideoModel(
            id: id,
            title: 'Video',
            url: 'https://example.com/$id',
          ),
        ),
      );

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async {
    lastRequest = (id, preferHeight, preferStreamId);
    return Result.success(
      MediaStream(
        videoUrl: 'https://cdn.example/low.m4s',
        height: preferHeight,
        streamId: preferStreamId,
      ),
    );
  }

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
}
