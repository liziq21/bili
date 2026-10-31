import 'package:app/data/repository/app_live_room_repository.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

class _FakeLiveDataSource extends LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    return Result.success(
      const LiveRoomDetail(
        roomId: 12345,
        title: 'Test Live Room',
        anchorName: 'Streamer',
        online: 100,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) async {
    return Result.error(Exception('Stream unavailable'));
  }
}

class _FakeLiveDataSourceWithStream extends LiveRoomDetailRemoteDataSource {
  _FakeLiveDataSourceWithStream(this._stream);

  final MediaStream _stream;

  @override
  String get sourceId => 'fake';

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    return Result.success(
      const LiveRoomDetail(
        roomId: 12345,
        title: 'Test Live Room',
        anchorName: 'Streamer',
        online: 100,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) async {
    return Result.success(_stream);
  }
}

void main() {
  testWidgets('LiveScreen displays stream error and retry button', (
    tester,
  ) async {
    final repo = AppLiveRoomRepository(_FakeLiveDataSource());

    await tester.pumpWidget(
      Provider<AppLiveRoomRepository>.value(
        value: repo,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LiveScreen(roomId: '12345'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load live stream'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('LiveScreen danmaku settings button has localized tooltip', (
    tester,
  ) async {
    final mediaStream = MediaStream(
      url: 'https://example.com/live.m3u8',
      format: StreamFormat.hls,
    );
    final repo = AppLiveRoomRepository(
      _FakeLiveDataSourceWithStream(mediaStream),
    );

    await tester.pumpWidget(
      Provider<AppLiveRoomRepository>.value(
        value: repo,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const LiveScreen(roomId: '12345'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Toggle fullscreen to show overlay controls.
    final toggleFullscreenFinder = find.byTooltip('Fullscreen');
    if (toggleFullscreenFinder.evaluate().isNotEmpty) {
      await tester.tap(toggleFullscreenFinder);
      await tester.pumpAndSettle();
    }

    final l10n = AppLocalizations.of(tester.element(find.byType(LiveScreen)))!;
    final danmakuSettingsButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip == l10n.danmakuSettingsTitle &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.forum_outlined,
    );
    expect(danmakuSettingsButton, findsOneWidget);
  });
}
