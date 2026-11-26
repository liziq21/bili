import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:model/model.dart';

import '../../../data/repository/channel_playlists_repository.dart';

/// 频道页播放列表 tab 的分页状态机。
///
/// 只按页拉取远端播放列表头，不写本地库；翻页键是页码，从 1 开始。
///
/// 接口把合集和系列混在同一分页里，而这里只展示能打开详情的合集。某一页
/// 全是系列时该页为空，`PagedListView` 见到空页就不会再翻页，因此这里继续
/// 请求后续页直到拿到可显示条目或读完所有页。
class ChannelPlaylistsCubit(
  final ChannelPlaylistsRepository _repository,
  final String _channelId,
) extends Cubit<PagingState<int, PlaylistDetail>> {
  this : super(PagingState());

  static const int _pageSize = 30;

  int _nextPage = 1;

  Future<void> fetchNextPage() async {
    if (state.isLoading) return;
    if (!state.hasNextPage) return;

    emit(state.copyWith(isLoading: true, error: null));

    while (true) {
      final page = _nextPage;
      final result = await _repository.fetchPlaylists(
        channelId: _channelId,
        page: page,
        pageSize: _pageSize,
      );
      if (isClosed) return;

      switch (result) {
        case Success(:final success):
          final hasNextPage = page < success.totalPages;
          _nextPage = page + 1;
          if (success.data.isEmpty && hasNextPage) continue;
          emit(
            state.copyWith(
              pages: [...state.pages, success.data],
              keys: [...state.keys, page],
              hasNextPage: hasNextPage,
              isLoading: false,
              error: null,
            ),
          );
          return;
        case Error(:final error):
          emit(state.copyWith(error: error, isLoading: false));
          return;
      }
    }
  }
}
