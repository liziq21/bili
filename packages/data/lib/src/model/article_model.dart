import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// 频道专栏文章（与 `VideoModel` 平行的只读条目）。
///
/// 只保留订阅 Feed 需要的字段：文章在应用内没有阅读页，打开动作按 [url]
/// 处理，因此不携带正文。
@immutable
final class const ArticleModel({
  required final String id,
  required final String title,
  required final String url,
  final String? thumbnailUrl,
  final DateTime? publishedAt,
  final String? creatorProfileName,
  final String? creatorProfileId,
}) with Equatable {
  @override
  List<Object?> get props => [
    id,
    title,
    url,
    thumbnailUrl,
    publishedAt,
    creatorProfileName,
    creatorProfileId,
  ];
}
