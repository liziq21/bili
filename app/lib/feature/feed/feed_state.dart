import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../database/app_database.dart';

/// 订阅动态里的一个频道分组
///
/// 条目来自本地 `feed_entry` 表：加载器已按频道落库，这里只做展示分组，
/// 不再请求远端。频道名优先取订阅表里的名字，退订后条目自带的
/// `creatorProfileName` 仍在，所以已有条目不会失去标题。
@immutable
final class const FeedChannelGroup({
  required final String channelId,
  required final String channelName,
  final String? thumbnailUrl,
  final List<FeedEntryEntity> entries = const [],
  final int unreadCount = 0,
}) extends Equatable {
  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [
    channelId,
    channelName,
    thumbnailUrl,
    entries,
    unreadCount,
  ];
}

@immutable
final class const FeedState({
  final bool isLoading = true,
  final Object? error,
  final List<FeedChannelGroup> groups = const [],

  /// 用户主动收起的频道。默认全部展开：进来就能看到新条目，收起是省空间的
  /// 手段而不是默认态。
  final Set<String> collapsedChannelIds = const {},
}) extends Equatable {
  bool get hasError => error != null;

  bool get isEmpty => !isLoading && error == null && groups.isEmpty;

  int get unreadCount =>
      groups.fold(0, (sum, group) => sum + group.unreadCount);

  bool isExpanded(String channelId) => !collapsedChannelIds.contains(channelId);

  FeedState copyWith({
    bool? isLoading,
    Object? error,
    bool clearError = false,
    List<FeedChannelGroup>? groups,
    Set<String>? collapsedChannelIds,
  }) => FeedState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    groups: groups ?? this.groups,
    collapsedChannelIds: collapsedChannelIds ?? this.collapsedChannelIds,
  );

  @override
  List<Object?> get props => [isLoading, error, groups, collapsedChannelIds];
}
