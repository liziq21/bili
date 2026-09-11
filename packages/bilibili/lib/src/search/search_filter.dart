import 'package:data/data.dart';

enum VideoDurationFilterOption implements FilterOption {
  allDuration('不限'),
  below10Minutes('10分钟以下'),
  tenTo30Minutes('10-30分钟'),
  thirtyTo60Minutes('30-60分钟'),
  above60Minutes('60分钟以上');

  const VideoDurationFilterOption(this.label);

  @override
  final String label;

  @override
  String get value => name;
}

enum UserType implements FilterOption {
  allUsers('全部用户'),
  upMain('UP主'),
  normalUser('普通用户'),
  verifiedUser('认证用户');

  const UserType(this.label);

  @override
  final String label;

  @override
  String get value => '$index';
}

class VideoDurationFilter extends SingleFilterGroup {
  const VideoDurationFilter()
    : super(
        key: 'duration',
        label: '时长',
        options: VideoDurationFilterOption.values,
        selection: VideoDurationFilterOption.allDuration,
      );
}

class BiliDateRangeFilterGroup extends DateRangeFilterGroup {
  const BiliDateRangeFilterGroup() : super(key: 'pubdate', label: '发布时间');
}
