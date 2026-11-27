import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// 让横向滚动视图在桌面端响应普通鼠标滚轮。
///
/// [Scrollable] 只用滚轮事件中与自身轴向一致的增量：横向列表读取
/// `scrollDelta.dx`，而普通滚轮只给出 `dy`，因此鼠标停在横向列表上滚动
/// 时列表纹丝不动，内容超出视口的部分没有任何可达路径。这里把纵向增量
/// 转发给横向滚动位置。
///
/// 只处理鼠标滚轮（[PointerDeviceKind.mouse]）：网页端触控板的纵向手势以
/// [PointerDeviceKind.trackpad] 送达，应由外层页面消费。
///
/// 通过 [PointerSignalResolver] 认领事件而不是直接滚动，是为了和
/// [Scrollable] 的仲裁规则保持一致：
/// * 按 Shift（[ScrollBehavior.pointerAxisModifiers]）滚轮时，[Scrollable]
///   自己会把轴向翻转并先一步认领事件，这里不能再叠加一次。
/// * 列表已经滚到头时这里不认领，事件落回外层纵向列表，滚轮可以继续
///   把页面往下滚，而不是在边界处变成死区。
class const HorizontalWheelScroll({
  super.key,
  required final Widget Function(
    BuildContext context,
    ScrollController controller,
  )
  builder,
}) extends StatefulWidget {
  @override
  State<HorizontalWheelScroll> createState() => _HorizontalWheelScrollState();
}

class _HorizontalWheelScrollState() extends State<HorizontalWheelScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(BuildContext context, PointerSignalEvent event) {
    // 只重映射鼠标滚轮。触控板的纵向手势在网页端以 trackpad 事件送达，
    // 交给外层页面处理，否则嵌在纵向页面里的横排会把页面的上下滚动截走。
    if (event is! PointerScrollEvent || event.kind != PointerDeviceKind.mouse) {
      return;
    }
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    // Shift+滚轮由 Scrollable 翻转轴向自行处理，重复认领会滚两倍。
    if (HardwareKeyboard.instance.logicalKeysPressed.any(
      ScrollConfiguration.of(context).pointerAxisModifiers.contains,
    )) {
      return;
    }
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      position.pointerScroll(delta);
      event.respond(allowPlatformDefault: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) => _onPointerSignal(context, event),
      child: widget.builder(context, _controller),
    );
  }
}
