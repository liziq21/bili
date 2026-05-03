import '../../model/data/filter_group.dart';

enum VideoDurationFilterOption implements FilterOption {
  allDuration('不限'),
  below10Minutes('below10Minutes'),
  tenTo30Minutes('tenTo30Minutes'),
  thirtyTo60Minutes('thirtyTo60Minutes'),
  above60Minutes('above60Minutes');

  const VideoDurationFilterOption(this.label);
  
  @override
  final String label;
  
  @override
  String get value => name;
}

/*
全部用户(默认)：0
up主：1
普通用户：2
认证用户：3
*/
enum UserType implements FilterOption {
  allUsers('allUsers'),
  upMain('upMain'),
  normalUser('normalUser'),
  verifiedUser('verifiedUser');
  
  const UserType(this.label);
  
  @override
  final String label;
  
  @override
  String get value => index;
}

class BiliVideoDurationFilter implements FilterGroup<VideoDurationFilterOption> {
  const BiliVideoDurationFilter() : super(
    label: 'BiliVideoDurationFilter',
    options: VideoDurationFilterOption.values,
    allowMultipleSelection: false,
    selectedOptions : [],
  );
  
  @override
  DateRangeFilter copyWith({
    List<DateRangePresetOption>? selectedOptions,
    ({DateTime start, DateTime end})? customDateRange,
  }) {
    return DateRangeFilter(
      label: label,
      options: options,
      allowMultipleSelection: allowMultipleSelection,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      customDateRange: customDateRange ?? this.customDateRange,
    );
  }
  
  @override
  Map<String, dynamic> toJson() => {
    
  }
}

class BiliSearchDateRangeFilter implements DateRangeFilter {
  
}
