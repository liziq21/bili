/// 计时归零时的行为。
enum SleepTimerAction() {
  /// 归零即暂停当前播放。
  pauseNow,

  /// 本条照播完，等队列要进下一条时再暂停。
  ///
  /// 队列循环 / 单曲循环下媒体播完会自动进下一条，故到点本身不干预，
  /// 真正的停点在队列序号变化的那一刻。
  afterCurrent,

  /// 归零即暂停并关闭播放器页面，回到上一个页面。
  ///
  /// 只是弹出播放页，不退出应用进程。
  exitPlayer;

  /// 从持久化值解析；未知值返回 null，交由调用方回退到旧键或默认值。
  static SleepTimerAction? fromStorage(String? value) {
    for (final action in values) {
      if (action.name == value) return action;
    }
    return null;
  }
}
