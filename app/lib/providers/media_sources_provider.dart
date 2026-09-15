import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:youtube/youtube.dart';

final List<MediaSource> defaultMediaSources = [
  Bili(),
  YouTube(),
];

extension MediaSourcesContextX on BuildContext {
  List<MediaSource> get mediaSources => watch<List<MediaSource>>();

  List<String> get availableSourceIds =>
      mediaSources.map((source) => source.id).toList();
}
