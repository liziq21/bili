import 'dart:ui' show SemanticsAction;

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/quality_picker_chip.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';

Future<void> _pumpQualityPicker(WidgetTester tester, MediaStream stream) async {
  final repository = _RecordingVideoDetailRepository();
  final bloc = VideoBloc(repository: repository);
  final controller = _RecordingPlaybackController();
  addTearDown(bloc.close);
  addTearDown(controller.dispose);

  bloc.add(const LoadVideoDetail('video'));
  await tester.pump();
  await tester.pump();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: RepositoryProvider<VideoDetailRepository>.value(
            value: repository,
            child: QualityPickerChip(controller: controller, stream: stream),
          ),
        ),
      ),
    ),
  );
}

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
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
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
      expect(find.byIcon(AppIcons.check), findsOneWidget);

      await tester.tap(find.text('1080P low'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(repository.lastRequest, ('video', 1080, 81));
      expect(bloc.state.mediaStream?.streamId, 81);
      expect(controller.openedStreams, isEmpty);
    },
  );

  testWidgets('drops rows whose rendered label and bitrate are identical', (
    tester,
  ) async {
    await _pumpQualityPicker(
      tester,
      MediaStream(
        videoUrl: 'https://cdn.example/high.m4s',
        height: 1080,
        bitrate: 3_000_000,
        streamId: 80,
        qualityLabel: '1080P',
        alternatives: [
          // 两个码率经一位小数格式化后都是 0.1 Mbps。
          MediaQualityOption(
            height: 360,
            label: '360P',
            streamId: 16,
            bitrate: 119_861,
          ),
          MediaQualityOption(
            height: 360,
            label: '360P',
            streamId: 17,
            bitrate: 105_025,
          ),
          MediaQualityOption(
            height: 360,
            label: '360P',
            streamId: 18,
            bitrate: 400_000,
          ),
        ],
      ),
    );

    await tester.tap(find.text('1080P'));
    await tester.pumpAndSettle();

    // 渲染结果相同的两行 360P 只保留一行；不同码率的两档都保留。
    expect(find.text('360P'), findsNWidgets(2));
    expect(find.text('0.1 Mbps'), findsOneWidget);
    expect(find.text('0.4 Mbps'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('keeps streams that differ only by codec', (tester) async {
    await _pumpQualityPicker(
      tester,
      MediaStream(
        videoUrl: 'https://cdn.example/high.m4s',
        height: 1080,
        bitrate: 3_000_000,
        streamId: 80,
        qualityLabel: '1080P',
        alternatives: [
          MediaQualityOption(
            height: 720,
            label: '720P',
            streamId: 64,
            bitrate: 1_000_000,
            codecs: 'avc1.640028',
            frameRate: '30',
          ),
          MediaQualityOption(
            height: 720,
            label: '720P',
            streamId: 65,
            bitrate: 1_000_000,
            codecs: 'hev1.1.6.L120.90',
            frameRate: '30',
          ),
        ],
      ),
    );

    await tester.tap(find.text('1080P'));
    await tester.pumpAndSettle();

    expect(find.text('720P'), findsNWidgets(2));
    expect(find.text('1.0 Mbps | AVC | 30 fps'), findsOneWidget);
    expect(find.text('1.0 Mbps | HEVC | 30 fps'), findsOneWidget);
  });

  testWidgets('keeps height order after the current row replaces a duplicate', (
    tester,
  ) async {
    await _pumpQualityPicker(
      tester,
      MediaStream(
        videoUrl: 'https://cdn.example/high.m4s',
        height: 360,
        bitrate: 200_000,
        streamId: 16,
        qualityLabel: 'HD',
        alternatives: [
          MediaQualityOption(
            height: 720,
            label: 'HD',
            streamId: 64,
            bitrate: 200_000,
          ),
          MediaQualityOption(
            height: 480,
            label: 'HD',
            streamId: 32,
            bitrate: 500_000,
          ),
        ],
      ),
    );

    await tester.tap(find.text('HD'));
    await tester.pumpAndSettle();

    expect(find.text('HD'), findsNWidgets(3));
    final higherY = tester.getTopLeft(find.text('0.5 Mbps')).dy;
    final currentY = tester.getTopLeft(find.text('0.2 Mbps')).dy;
    expect(higherY, lessThan(currentY));
  });

  testWidgets('the sheet title aligns with the option text', (tester) async {
    await _pumpQualityPicker(
      tester,
      MediaStream(
        videoUrl: 'https://cdn.example/high.m4s',
        height: 1080,
        bitrate: 4_000_000,
        streamId: 80,
        qualityLabel: '1080P',
        alternatives: [
          MediaQualityOption(
            height: 720,
            label: '720P',
            streamId: 64,
            bitrate: 2_000_000,
          ),
        ],
      ),
    );

    await tester.tap(find.text('1080P'));
    await tester.pumpAndSettle();

    final titleX = tester.getTopLeft(find.text('Select quality')).dx;
    final optionX = tester.getTopLeft(find.text('720P')).dx;
    expect((titleX - optionX).abs(), lessThan(0.5));
  });

  testWidgets('the chip opens the picker from a screen-reader tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = _RecordingVideoDetailRepository();
    final bloc = VideoBloc(repository: repository);
    final controller = _RecordingPlaybackController();
    addTearDown(bloc.close);
    addTearDown(controller.dispose);

    bloc.add(const LoadVideoDetail('video'));
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: RepositoryProvider<VideoDetailRepository>.value(
              value: repository,
              child: QualityPickerChip(
                controller: controller,
                stream: MediaStream(
                  videoUrl: 'https://cdn.example/high.m4s',
                  height: 1080,
                  qualityLabel: '1080P high',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel('Select quality 1080P high'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(find.text('1080P high'), findsNWidgets(2));
    semantics.dispose();
  });
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
