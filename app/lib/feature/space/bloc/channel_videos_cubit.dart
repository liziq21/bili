import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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

  Future<void> fetchNextPage() async {
    if (state.isLoading) return;
    if (state.pages != null && !state.hasNextPage) return;

    final keys = state.keys;
    final nextPage = (keys == null || keys.isEmpty ? 0 : keys.last) + 1;
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
            pages: [...?state.pages, success.data],
            keys: [...?state.keys, nextPage],
            hasNextPage: nextPage < success.totalPages,
            isLoading: false,
            error: null,
          ),
        );
      case Error(:final error):
        emit(state.copyWith(error: error, isLoading: false));
    }
  }
}
