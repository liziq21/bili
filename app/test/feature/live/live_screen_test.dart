import 'package:app/data/repository/app_live_room_repository.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

class _FakeLiveDataSource() extends LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  /// 置为 true 时详情接口失败，页面进入整页错误态。
  bool failDetail = false;

  /// 详情接口返回的在线人数。
  int online = 100;

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    if (failDetail) {
      return Result.error(Exception('room detail offline'));
    }
    return Result.success(
      LiveRoomDetail(
        roomId: 12345,
        title: 'Test Live Room',
        anchorName: 'Streamer',
        online: online,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) async {
    return Result.error(Exception('Stream unavailable'));
  }
}

Widget _buildScreen(_FakeLiveDataSource source, {Locale? locale}) {
  return Provider<AppLiveRoomRepository>.value(
    value: AppLiveRoomRepository(source),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LiveScreen(roomId: '12345'),
    ),
  );
}

void main() {
  testWidgets('LiveScreen displays stream error and retry button', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(_FakeLiveDataSource()));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load live stream'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('the app bar title follows the active locale', (tester) async {
    await tester.pumpWidget(
      _buildScreen(_FakeLiveDataSource(), locale: const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('直播间'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
  });

  testWidgets('the app bar title is English under the English locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(_FakeLiveDataSource(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('直播间'), findsNothing);
  });

  testWidgets('the viewer count uses the same compact format as cards', (
    tester,
  ) async {
    final source = _FakeLiveDataSource()..online = 155266;

    await tester.pumpWidget(_buildScreen(source, locale: const Locale('zh')));
    await tester.pumpAndSettle();

    expect(find.text('15.5万 观看'), findsOneWidget);
    expect(find.textContaining('155266'), findsNothing);
  });

  testWidgets('a detail failure shows the category copy, never the exception', (
    tester,
  ) async {
    final source = _FakeLiveDataSource()..failDetail = true;

    await tester.pumpWidget(_buildScreen(source));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load live room'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('room detail offline'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
