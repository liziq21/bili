import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/channel_videos_repository.dart';

/// 频道页视频 tab 的分页状态机。
///
/// 只按页拉取远端投稿，不写本地库；翻页键是页码，从 1 开始。
class ChannelVideosCubit(
  final ChannelVideosRepository _repository,
  final String _channelId,
) extends Cubit<PagingState<int, VideoModel>> {
  this : super(PagingState());

  static const int _pageSize = 30;

  final _log = Logger('ChannelVideosCubit');

  Future<void> fetchNextPage() async {
    if (state.isLoading) return;
    if (!state.hasNextPage) return;

    final nextPage = state.nextIntPageKey;
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _repository.fetchVideos(
      channelId: _channelId,
      page: nextPage,
      pageSize: _pageSize,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final success):
        emit(
          state.copyWith(
            pages: [...state.pages, success.data],
            keys: [...state.keys, nextPage],
            hasNextPage: nextPage < success.totalPages,
            isLoading: false,
            error: null,
          ),
        );
      case Error(:final error):
        _log.warning(
          'Failed to load channel videos (mid: $_channelId, page: $nextPage)',
          error,
        );
        emit(state.copyWith(error: error, isLoading: false));
    }
  }
}
