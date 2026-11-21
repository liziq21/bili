import 'package:flutter/foundation.dart';

/// 管理搜索页输入框的聚焦请求，替代全局可变闭包。
class SearchFocusController() extends ChangeNotifier {
  VoidCallback? _focusCallback;

  /// 由 SearchScreen 在挂载时注册聚焦动作，销毁时传入 null 注销。
  void register(VoidCallback? callback) {
    _focusCallback = callback;
  }

  /// 底栏重复点击搜索Tab时触发聚焦。
  void requestFocus() {
    _focusCallback?.call();
  }
}
