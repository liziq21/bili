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
