import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

import '../../routing/routes.dart';
import 'feed_update_notifier.dart';

/// 把「用户点了订阅更新通知」变成一次页面跳转。
///
/// 挂在导航骨架之上，所以应用在前台时点击通知、以及通知直接拉起冷启动，
/// 都走同一条路径：监听 [FeedUpdateNotifier.feedOpened]，交给 [onOpenFeed]。
///
/// 冷启动的点击在 [FeedUpdateNotifier.initialize] 里落地，可能早于本组件
/// 订阅；notifier 会把它缓存到首个订阅者，这里不必自己补一个「启动时检查」。
class const FeedNotificationListener({
  super.key,
  required final Widget child,

  /// 打开订阅动态页。缺省时按 [Routes.feed] 走底栏分支。
  ///
  /// 显式传入是为了让测试能断言「点击后要求打开 Feed」，而不必拉起整棵
  /// provider 树与真实路由。
  final VoidCallback? onOpenFeed,
}) extends StatefulWidget {
  @override
  State<FeedNotificationListener> createState() =>
      _FeedNotificationListenerState();
}

class _FeedNotificationListenerState() extends State<FeedNotificationListener> {
  final _log = Logger('FeedNotificationListener');
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    // 读一次而不是 watch：provider 在应用生命周期内不换实例，点击流自己
    // 负责后续事件。
    final notifier = context.read<FeedUpdateNotifier?>();
    if (notifier == null || !notifier.isSupported) return;

    _subscription = notifier.feedOpened.listen(
      (_) => _openFeed(),
      onError: (Object error, StackTrace stackTrace) =>
          _log.warning('Feed notification stream failed', error, stackTrace),
    );

    // 建通道、注册点击回调、消费冷启动点击。不弹权限框：权限由设置页在
    // 用户显式开启时申请。
    unawaited(
      notifier.initialize().then((result) {
        if (result case Error(:final error)) {
          _log.warning('Feed notification init failed', error);
        }
      }),
    );
  }

  void _openFeed() {
    if (!mounted) return;
    final onOpenFeed = widget.onOpenFeed;
    if (onOpenFeed != null) {
      onOpenFeed();
      return;
    }
    // 走底栏分支而不是 push：订阅动态是主分支之一，点击通知应把它设为当前
    // 分支，返回键不该退回到用户离开前的页面。
    context.go(Routes.feed);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
