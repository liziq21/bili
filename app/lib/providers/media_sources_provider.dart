import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:youtube/youtube.dart';

/// 默认支持的媒体数据源列表
final List<MediaSource> defaultMediaSources = [Bili(), YouTube()];

/// 便捷获取 BuildContext 中注册的媒体数据源列表扩展
extension MediaSourcesContextX on BuildContext {
  /// 监听并获取可用 [MediaSource] 实例列表
  List<MediaSource> get mediaSources => watch<List<MediaSource>>();

  /// 获取当前所有可用数据源的标识符 (ID) 列表
  List<String> get availableSourceIds =>
      mediaSources.map((source) => source.id).toList();
}

/// 把持久化的数据源标识解析成当前生效的标识
///
/// 全 app 唯一一处「未选择过 / 脏值」与「生效值」之间的转换点：持久值为 null
///（用户尚未选择过）或不在 [sources] 清单内时，回退到清单首项；清单为空时返回
/// 空标识而不是崩溃或写死某个服务名。
///
/// 首页由 HomeBloc 解析、搜索分支由路由解析，两处共用本函数：规则一旦分叉，同一
/// 个持久值会在两个页面解析出不同的源（表现为选了 YouTube、搜索页仍搜 B 站）。
String resolveMediaSourceId(List<MediaSource> sources, String? persisted) {
  if (persisted != null && sources.any((s) => s.id == persisted)) {
    return persisted;
  }
  return sources.isEmpty ? '' : sources.first.id;
}
