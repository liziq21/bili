// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_reply_reply_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkReplyReplyData _$NetworkReplyReplyDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkReplyReplyData', json, ($checkedConvert) {
  final val = NetworkReplyReplyData(
    page: $checkedConvert(
      'page',
      (v) => v == null
          ? null
          : NetworkReplyPage.fromJson(v as Map<String, dynamic>),
    ),
    root: $checkedConvert(
      'root',
      (v) => v == null
          ? null
          : NetworkReplyItem.fromJson(v as Map<String, dynamic>),
    ),
    replies: $checkedConvert(
      'replies',
      (v) => (v as List<dynamic>?)
          ?.map((e) => NetworkReplyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    upper: $checkedConvert(
      'upper',
      (v) => v == null
          ? null
          : NetworkReplyUpper.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

NetworkReplyPage _$NetworkReplyPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyPage', json, ($checkedConvert) {
      final val = NetworkReplyPage(
        num: $checkedConvert('num', (v) => (v as num?)?.toInt()),
        size: $checkedConvert('size', (v) => (v as num?)?.toInt()),
        count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
      );
      return val;
    });
