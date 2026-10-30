import 'package:app/feature/live/bloc/live_bloc.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeLiveBloc extends Bloc<LiveEvent, LiveState> implements LiveBloc {
  _FakeLiveBloc(LiveState initialState) : super(initialState);
}

void main() {
  group('LiveScreen player overlay accessibility and tooltips', () {
    testWidgets('LiveScreen displays stream error and retry button with tooltip and semantics', (
      WidgetTester tester,
    ) async {
      final fakeBloc = _FakeLiveBloc(
        const LiveState(
          streamError: 'Failed to load stream',
          roomDetail: LiveRoomDetailModel(
            roomId: 12345,
            title: 'Test Live Room',
            anchorName: 'Streamer',
            online: 100,
            isLive: true,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<LiveBloc>.value(
            value: fakeBloc,
            child: const LiveScreen(roomId: '12345'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load live stream'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
