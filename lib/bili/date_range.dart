extension DateTimeExtension on DateTime {
  DateTime toSecondPrecision() => DateTime(year, month, day, hour, minute, second);
  DateTime get addOneSecond => add(const Duration(seconds: 1));
  DateTime get subtractOneSecond => subtract(const Duration(seconds: 1));
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfDay => DateTime(year, month, day);
}


// DO follow API design principles
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.end,
  }) : assert(start.isBefore(end), 'Start must be before end');
  
  final DateTime start;
  final DateTime end;
}

class DateRange {
  static final globalMinDateLimit = DateTime(2009, 6, 26);
  static get globalMaxDateLimit => DateTime.now().toSecondPrecision();
  
  static final DateTime selectableMinDate = globalMinDateLimit.addOneSecond;
  static get selectableMaxDate => globalMaxDateLimit.subtractOneSecond;

  DateTime _start;
  DateTime _end;

  DateTime get start => _start;
  DateTime get end => _end;

  set start(DateTime newStart) {
    _start = newStart.toSecondPrecision();
    _validateStartLimit();
    if (_hasConflict()) {
      end = _start.addOneSecond;
    }
  }

  set end(DateTime newEnd) {
    _end = newEnd.toSecondPrecision();
    _validateEndLimit();
    if (_hasConflict()) {
      start = _end.subtractOneSecond;
    }
  }

  DateRange({
    DateTime? start,
    DateTime? end,
  }) :
    _start = start ?? globalMinDateLimit,
    _end = end ?? globalMaxDateLimit
  {
    if (_hasConflict()) {
      throw ArgumentError('End date must be at least one day after the start date.');
    }
    _validateStartLimit();
    _validateEndLimit();
  }
  
  void _validateStartLimit() {
    if (_start.isBefore(globalMinDateLimit)) {
      throw ArgumentError('Start date cannot be before $globalMinDateLimit.');
    }
  }
  
  void _validateEndLimit() {
    if (_end.isAfter(globalMaxDateLimit)) {
      throw ArgumentError('End date cannot be in the future (beyond today: $globalMaxDateLimit).');
    }
  }

  bool _hasConflict() => _end.isBefore(_start);

  @override
  String toString() {
    return 'DateRange(start: $_start, end: $_end)';
  }
}