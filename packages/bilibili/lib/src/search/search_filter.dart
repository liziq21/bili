import 'package:data/data.dart';

enum VideoDurationFilterOption(
  @override
  final String label) implements FilterOption {
  allDuration('不限'),
  below10Minutes('10分钟以下'),
  tenTo30Minutes('10-30分钟'),
  thirtyTo60Minutes('30-60分钟'),
  above60Minutes('60分钟以上');

  @override
  String get value => name;
}

enum UserType(
  @override
  final String label) implements FilterOption {
  allUsers('全部用户'),
  upMain('UP主'),
  normalUser('普通用户'),
  verifiedUser('认证用户');

  @override
  String get value => '$index';
}

class const VideoDurationFilter() extends SingleFilterGroup {
  this
    : super(
        key: 'duration',
        label: '时长',
        options: VideoDurationFilterOption.values,
        selection: VideoDurationFilterOption.allDuration,
      );
}

class const BiliDateRangeFilterGroup() extends DateRangeFilterGroup {
  this : super(key: 'pubdate', label: '发布时间');
}
