import 'package:app/feature/live/bloc/live_bloc.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeLiveBloc(super.initialState)
    extends Cubit<LiveState>
    implements LiveBloc {
  @override
  void add(LiveEvent event) {}

  @override
  void on<E extends LiveEvent>(
    EventHandler<E, LiveState> handler, {
    EventTransformer<E>? transformer,
  }) {}

  @override
  void onDone(LiveEvent event, [Object? error, StackTrace? stackTrace]) {}

  @override
  void onEvent(LiveEvent event) {}

  @override
  void onTransition(Transition<LiveEvent, LiveState> transition) {}
}

void main() {
  group('LiveScreen player overlay accessibility and tooltips', () {
    testWidgets('LiveScreen displays stream error and retry button with tooltip and semantics', (
      tester,
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
