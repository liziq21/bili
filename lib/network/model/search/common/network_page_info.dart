import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_page_info.freezed.dart';
part 'network_page_info.g.dart';

@freezed
abstract class NetworkPageinfo with _$NetworkPageinfo {
  const factory NetworkPageinfo({
    required int total,
    required int numResults,
    required int pages,
  }) = _NetworkPageinfo;
  
  factory NetworkPageinfo.fromJson(Map<String, int> json)
    => _$NetworkPageinfoFromJson(json);
}