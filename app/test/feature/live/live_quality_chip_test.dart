import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:app/data/repository/app_live_room_repository.dart';

import 'package:app/feature/live/bloc/live_bloc.dart';
import 'package:app/feature/live/live_quality_picker.dart';

import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:app/design/design.dart';

/// 直播房间数据源桩：记录调用、返回可播放流。
class _FakeLiveRoomDataSource() implements LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  int? lastPreferQn;

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    return Result.success(
      LiveRoomDetail(
        roomId: roomId,
        title: 'Title',
        anchorName: 'Anchor',
        online: 0,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) async {
    lastPreferQn = preferQn;
    return Result.success(
      MediaStream(
        videoUrl: 'https://example.com/live.m3u8',
        streamId: preferQn ?? 10000,
        qualityLabel: 'Auto',
      ),
    );
  }
}

/// 由测试控制的房间数据源：让 chip 停在「切换中」状态，直到测试放行。
class _PendingLiveRoomStreamDataSource(
  final Future<Result<MediaStream, Exception>> pendingStream,
) implements LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async => Result.success(
    LiveRoomDetail(
      roomId: roomId,
      title: 'Title',
      anchorName: 'Anchor',
      online: 0,
      isLive: true,
    ),
  );

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) => pendingStream;
}

/// 在 testWidgets 的 fake-async zone 里显式推进事件队列，
/// 避免 `pumpEventQueue()` 在某些 Flutter 版本上挂死（见 flutter-bloc-widget-test-zones skill）。
Future<void> _pumpEventQueue(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'The quality chip shows the current quality and switches on select',
    (tester) async {
      final dataSource = _FakeLiveRoomDataSource();
      final stream = MediaStream(
        videoUrl: 'https://example.com/live_150.m3u8',
        streamId: 150,
        qualityLabel: 'HD',
        alternatives: [
          MediaQualityOption(streamId: 10000, label: 'Auto'),
          MediaQualityOption(streamId: 400, label: 'FHD'),
          MediaQualityOption(streamId: 250, label: 'HD+'),
        ],
      );
      final bloc = LiveBloc(repository: AppLiveRoomRepository(dataSource));
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: LiveQualityChip(stream: stream, roomId: 21144080),
            ),
          ),
        ),
      );

      // 按钮显示当前档。
      expect(find.text('HD'), findsOneWidget);

      // 点开选择器。
      await tester.tap(find.text('HD'));
      await tester.pumpAndSettle();

      // 当前档在弹窗里勾选，候选项列出。
      expect(find.text('HD'), findsNWidgets(2));
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('HD+'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsOneWidget);

      // 选「HD+」→ 以该 qn 请求。
      await tester.tap(find.text('HD+'));
      await _pumpEventQueue(tester);

      expect(dataSource.lastPreferQn, 250);
    },
  );

  testWidgets('the chip opens the picker from a screen-reader tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final stream = MediaStream(
      videoUrl: 'https://example.com/live_150.m3u8',
      streamId: 150,
      qualityLabel: 'HD',
      alternatives: [MediaQualityOption(streamId: 400, label: 'FHD')],
    );
    final bloc = LiveBloc(
      repository: AppLiveRoomRepository(_FakeLiveRoomDataSource()),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: LiveQualityChip(stream: stream, roomId: 21144080),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Quality HD'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    expect(find.text('FHD'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the chip drops its tap action while a switch is in flight', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final pending = Completer<Result<MediaStream, Exception>>();
    final stream = MediaStream(
      videoUrl: 'https://example.com/live_150.m3u8',
      streamId: 150,
      qualityLabel: 'HD',
      alternatives: [MediaQualityOption(streamId: 400, label: 'FHD')],
    );
    final bloc = LiveBloc(
      repository: AppLiveRoomRepository(
        _PendingLiveRoomStreamDataSource(pending.future),
      ),
    );
    addTearDown(bloc.close);

    // 先让 bloc 进入切档中，再建树：chip 的禁用态在首帧即成立，不依赖弹窗动画。
    bloc.add(const SwitchLiveQuality(21144080, 400));
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: LiveQualityChip(stream: stream, roomId: 21144080),
          ),
        ),
      ),
    );

    expect(bloc.state.isSwitchingQuality, isTrue);
    final node = tester.getSemantics(find.bySemanticsLabel('Quality HD'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    pending.complete(Result.error(Exception('switch aborted')));
    await tester.pump();
    semantics.dispose();
  });
}
