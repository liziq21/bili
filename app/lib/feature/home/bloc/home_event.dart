part of 'home_bloc.dart';

sealed class HomeEvent() {}

class _UserDataChanged(final UserData userData) extends HomeEvent;

class ServiceSourceChanged(final String sourceId) extends HomeEvent;

/// 拉取当前数据源的全部 Feed 首页数据
class FeedsRequested({final bool refresh = false}) extends HomeEvent;

/// 切换主页筛选项
class FilterSelected(final String filterId) extends HomeEvent;

/// 为指定 Feed 追加下一页
class FeedNextPageRequested(final String feedId) extends HomeEvent;
