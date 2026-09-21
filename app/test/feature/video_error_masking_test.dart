import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/bloc/video_comment_bloc.dart';
import 'package:app/feature/video/common_widgets/video_comments_view.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockVideoBloc extends Cubit<VideoState> implements VideoBloc {
  MockVideoBloc(super.initialState);

  @override
  void add(VideoEvent event) {}

  @override
  void on<E extends VideoEvent>(
    EventHandler<E, VideoState> handler, {
    EventTransformer<E>? transformer,
  }) {}

  @override
  void onDone(VideoEvent event, [Object? error, StackTrace? stackTrace]) {}

  @override
  void onEvent(VideoEvent event) {}

  @override
  void onTransition(Transition<VideoEvent, VideoState> transition) {}
}

class MockVideoCommentBloc extends Cubit<VideoCommentState>
    implements VideoCommentBloc {
  MockVideoCommentBloc(super.initialState);

  @override
  void add(VideoCommentEvent event) {}

  @override
  void on<E extends VideoCommentEvent>(
    EventHandler<E, VideoCommentState> handler, {
    EventTransformer<E>? transformer,
  }) {}

  @override
  void onDone(
    VideoCommentEvent event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {}

  @override
  void onEvent(VideoCommentEvent event) {}

  @override
  void onTransition(
    Transition<VideoCommentEvent, VideoCommentState> transition,
  ) {}
}

void main() {
  group('Security Error Masking Widget Tests', () {
    testWidgets(
      'VideoInfoView masks raw internal exceptions and sensitive paths',
      (tester) async {
        const sensitiveError =
            'DATABASE_EXPOSED_PATH /data/user/0/com.bili/app.db at Line 42';
        final mockBloc = MockVideoBloc(const VideoState(error: sensitiveError));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<VideoBloc>.value(
                value: mockBloc,
                child: const VideoInfoView(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('视频加载失败，请重试'), findsOneWidget);
        expect(find.textContaining('DATABASE_EXPOSED_PATH'), findsNothing);
        expect(find.textContaining('/data/user/0'), findsNothing);

        await mockBloc.close();
      },
    );

    testWidgets(
      'VideoCommentsView masks raw internal stack traces and server errors',
      (tester) async {
        const sensitiveStack =
            'CRITICAL_SERVER_EXCEPTION: Bearer eyJhbGciOi... StackTrace #0';
        final mockCommentBloc = MockVideoCommentBloc(
          const VideoCommentState(error: sensitiveStack),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<VideoCommentBloc>.value(
                value: mockCommentBloc,
                child: const VideoCommentsView(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('评论加载失败，请稍后重试'), findsOneWidget);
        expect(find.textContaining('CRITICAL_SERVER_EXCEPTION'), findsNothing);
        expect(find.textContaining('Bearer eyJ'), findsNothing);

        await mockCommentBloc.close();
      },
    );
  });
}
