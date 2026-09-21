import 'package:logging/logging.dart';

final _log = Logger('ImageErrorListener');

/// 全局网络图片加载失败监听函数
///
/// 用于捕获图片组件加载过程中的异常并输出 warning 级别日志。
void imageErrorListener(Object error) {
  _log.warning('Failed to load image', error);
}
