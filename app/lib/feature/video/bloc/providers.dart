import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repository/video_comment_repository.dart';
import '../../../data/repository/video_detail_repository.dart';
import 'video_bloc.dart';
import 'video_comment_bloc.dart';

List<BlocProvider> getVideoBlocProviders(
  BuildContext context, {
  required String videoId,
  VideoDetailRepository? customDetailRepo,
  VideoCommentRepository? customCommentRepo,
}) {
  final detailRepo = customDetailRepo ?? context.read<VideoDetailRepository?>();
  final commentRepo =
      customCommentRepo ?? context.read<VideoCommentRepository?>();

  return [
    if (detailRepo != null)
      BlocProvider<VideoBloc>(
        create: (_) => VideoBloc(repository: detailRepo)
          ..add(LoadVideoDetail(videoId))
          ..add(LoadMediaStream(videoId)),
      ),
    if (commentRepo != null)
      BlocProvider<VideoCommentBloc>(
        create: (_) =>
            VideoCommentBloc(repository: commentRepo)
              ..add(LoadVideoComments(videoId)),
      ),
  ];
}
