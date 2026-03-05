abstract class SortOption {
  const SortOption(this.label);
  final String label;
}

enum BiliVideoSortOptions implements SortOption {
  totalrank('totalrank'),
  click('最多点击'),
  dm('最多弹幕'),
  pubdate('最新发布'),
  scores('scores'),
  stow('stow');
  
  const BiliVideoSortOptions._(this.label);
  
  @override
  final String label;
  
}

enum BiliLiveRoomSortOptions implements SortOption {
  online('online'),
  liveTime('liveTime');
  
  const LiveRoomSortOptions._(this.label);
  
  @override
  final String label;
}

enum BiliUserSortOptions implements SortOption {
  defaultOrder('defaultOrder'),
  fons('fons'),
  level('level');
  
  const BiliUserSortOptions._(this.label);
  
  @override
  final String label;
}