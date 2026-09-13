// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_reply_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkReplyData _$NetworkReplyDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyData', json, ($checkedConvert) {
      final val = NetworkReplyData(
        cursor: $checkedConvert(
          'cursor',
          (v) => v == null
              ? null
              : NetworkReplyCursor.fromJson(v as Map<String, dynamic>),
        ),
        replies: $checkedConvert(
          'replies',
          (v) => (v as List<dynamic>?)
              ?.map((e) => NetworkReplyItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        top: $checkedConvert(
          'top',
          (v) => v == null
              ? null
              : NetworkReplyTop.fromJson(v as Map<String, dynamic>),
        ),
        topReplies: $checkedConvert(
          'top_replies',
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
    }, fieldKeyMap: const {'topReplies': 'top_replies'});

NetworkReplyCursor _$NetworkReplyCursorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NetworkReplyCursor',
      json,
      ($checkedConvert) {
        final val = NetworkReplyCursor(
          isEnd: $checkedConvert('is_end', (v) => v as bool?),
          next: $checkedConvert('next', (v) => (v as num?)?.toInt()),
          prev: $checkedConvert('prev', (v) => (v as num?)?.toInt()),
          allCount: $checkedConvert('all_count', (v) => (v as num?)?.toInt()),
          mode: $checkedConvert('mode', (v) => (v as num?)?.toInt()),
          paginationStr: $checkedConvert('pagination_str', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'isEnd': 'is_end',
        'allCount': 'all_count',
        'paginationStr': 'pagination_str',
      },
    );

NetworkReplyTop _$NetworkReplyTopFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyTop', json, ($checkedConvert) {
      final val = NetworkReplyTop(
        admin: $checkedConvert(
          'admin',
          (v) => v == null
              ? null
              : NetworkReplyItem.fromJson(v as Map<String, dynamic>),
        ),
        upper: $checkedConvert(
          'upper',
          (v) => v == null
              ? null
              : NetworkReplyItem.fromJson(v as Map<String, dynamic>),
        ),
        vote: $checkedConvert(
          'vote',
          (v) => v == null
              ? null
              : NetworkReplyItem.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

NetworkReplyUpper _$NetworkReplyUpperFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyUpper', json, ($checkedConvert) {
      final val = NetworkReplyUpper(
        mid: $checkedConvert('mid', (v) => (v as num?)?.toInt()),
        name: $checkedConvert('name', (v) => v as String?),
        face: $checkedConvert('face', (v) => v as String?),
      );
      return val;
    });

NetworkReplyItem _$NetworkReplyItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyItem', json, ($checkedConvert) {
      final val = NetworkReplyItem(
        rpid: $checkedConvert('rpid', (v) => (v as num).toInt()),
        oid: $checkedConvert('oid', (v) => (v as num).toInt()),
        type: $checkedConvert('type', (v) => (v as num).toInt()),
        mid: $checkedConvert('mid', (v) => (v as num).toInt()),
        root: $checkedConvert('root', (v) => (v as num?)?.toInt()),
        parent: $checkedConvert('parent', (v) => (v as num?)?.toInt()),
        dialog: $checkedConvert('dialog', (v) => (v as num?)?.toInt()),
        count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
        rcount: $checkedConvert('rcount', (v) => (v as num?)?.toInt()),
        state: $checkedConvert('state', (v) => (v as num?)?.toInt()),
        ctime: $checkedConvert('ctime', (v) => (v as num?)?.toInt()),
        like: $checkedConvert('like', (v) => (v as num?)?.toInt()),
        action: $checkedConvert('action', (v) => (v as num?)?.toInt()),
        member: $checkedConvert(
          'member',
          (v) => v == null
              ? null
              : NetworkReplyMember.fromJson(v as Map<String, dynamic>),
        ),
        content: $checkedConvert(
          'content',
          (v) => v == null
              ? null
              : NetworkReplyContent.fromJson(v as Map<String, dynamic>),
        ),
        replies: $checkedConvert(
          'replies',
          (v) => (v as List<dynamic>?)
              ?.map((e) => NetworkReplyItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        upAction: $checkedConvert(
          'up_action',
          (v) => v == null
              ? null
              : NetworkUpAction.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'upAction': 'up_action'});

NetworkReplyMember _$NetworkReplyMemberFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyMember', json, ($checkedConvert) {
      final val = NetworkReplyMember(
        mid: $checkedConvert('mid', (v) => v as String),
        uname: $checkedConvert('uname', (v) => v as String),
        sex: $checkedConvert('sex', (v) => v as String),
        sign: $checkedConvert('sign', (v) => v as String),
        avatar: $checkedConvert('avatar', (v) => v as String),
      );
      return val;
    });

NetworkReplyContent _$NetworkReplyContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkReplyContent', json, ($checkedConvert) {
      final val = NetworkReplyContent(
        message: $checkedConvert('message', (v) => v as String),
        plat: $checkedConvert('plat', (v) => (v as num?)?.toInt()),
        device: $checkedConvert('device', (v) => (v as num?)?.toInt()),
        emote: $checkedConvert('emote', (v) => v as Map<String, dynamic>?),
      );
      return val;
    });

NetworkUpAction _$NetworkUpActionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkUpAction', json, ($checkedConvert) {
      final val = NetworkUpAction(
        like: $checkedConvert('like', (v) => v as bool?),
        reply: $checkedConvert('reply', (v) => v as bool?),
      );
      return val;
    });
