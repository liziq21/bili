import 'package:json_annotation/json_annotation.dart';

part 'network_page_info.g.dart';

@JsonSerializable(createToJson: false)
class const NetworkPageinfo({
  required final int total,
  required final int numResults,
  required final int pages,
}) {
  factory NetworkPageinfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkPageinfoFromJson(json);
}

// @freezed
// abstract class NetworkPageinfo with _$NetworkPageinfo {
//   const factory NetworkPageinfo({
//     required int total,
//     required int numResults,
//     required int pages,
//   }) = _NetworkPageinfo;
//
//   factory NetworkPageinfo.fromJson(Map<String, dynamic> json)
//     => _$NetworkPageinfoFromJson(json);
// }

