import 'package:app/app_scaffold.dart';
import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/design/design.dart';
import 'package:app/feature/video/bloc/video_comment_bloc.dart';
import 'package:app/feature/video/common_widgets/video_comments_view.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';

class _FakeVideoCommentRepository() implements VideoCommentRepository {
  final comment = VideoComment(
    id: 'c1',
    authorName: 'Commenter',
    content: 'Root comment',
    replyCount: 2,
    replies: [
      VideoComment(id: 'r1', authorName: 'Reply 1', content: 'Preview reply'),
    ],
  );

  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async => Result.ok(Page(number: page, totalPages: 1, data: [comment]));

  @override
  Future<Result<Page<VideoComment>>> getVideoCommentReplies(
    String videoId,
    String rootCommentId, {
    int page = 1,
    int pageSize = 20,
  }) async => Result.ok(
    Page(
      number: page,
      totalPages: 1,
      data: [
        comment.replies.first,
        VideoComment(id: 'r2', authorName: 'Reply 2', content: 'Loaded reply'),
      ],
    ),
  );
}

void main() {
  testWidgets('expands replies through an explicit control and keeps preview', (
    tester,
  ) async {
    final bloc = VideoCommentBloc(repository: _FakeVideoCommentRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: appThemeData(AppColors(BrandPalette.of(Brightness.light))),
        home: AppScaffold(
          child: Material(
            child: SizedBox(
              height: 600,
              child: BlocProvider.value(
                value: bloc,
                child: const VideoCommentsView(),
              ),
            ),
          ),
        ),
      ),
    );
    bloc.add(const LoadVideoComments('video'));
    await tester.pump();
    await tester.pump();

    final expandButton = find.byKey(const ValueKey('comment-replies-c1'));
    expect(find.text('2'), findsOneWidget);

    await tester.tap(expandButton);
    await tester.pump();
    await tester.pump();

    expect(find.text('Collapse replies'), findsOneWidget);
    expect(
      find.textContaining('Preview reply', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Loaded reply', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('comment-replies-c1')));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Collapse replies'), findsNothing);
  });
}
