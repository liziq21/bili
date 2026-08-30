class DateRange({DateTime? start, DateTime? end}) {
  this
    : _start = start ?? globalMinDateLimit, _end = end ?? globalMaxDateLimit {
    if (_hasConflict()) {
      throw ArgumentError(
        'End date must be at least one day after the start date.',
      );
    }
    _validateStartLimit();
    _validateEndLimit();
  }
  static final globalMinDateLimit = DateTime(2009, 6, 26);

  static final DateTime selectableMinDate = globalMinDateLimit.addOneSecond;
  static DateTime get globalMaxDateLimit => DateTime.now().toSecondPrecision();

  static DateTime get selectableMaxDate => globalMaxDateLimit.subtractOneSecond;
  DateTime _start;

  DateTime _end;
  DateTime get end => _end;

  set end(DateTime newEnd) {
    _end = newEnd.toSecondPrecision();
    _validateEndLimit();
    if (_hasConflict()) {
      start = _end.subtractOneSecond;
    }
  }

  DateTime get start => _start;

  set start(DateTime newStart) {
    _start = newStart.toSecondPrecision();
    _validateStartLimit();
    if (_hasConflict()) {
      end = _start.addOneSecond;
    }
  }

  @override
  String toString() {
    return 'DateRange(start: $_start, end: $_end)';
  }

  bool _hasConflict() => _end.isBefore(_start);

  void _validateEndLimit() {
    if (_end.isAfter(globalMaxDateLimit)) {
      throw ArgumentError(
        'End date cannot be in the future (beyond today: $globalMaxDateLimit).',
      );
    }
  }

  void _validateStartLimit() {
    if (_start.isBefore(globalMinDateLimit)) {
      throw ArgumentError('Start date cannot be before $globalMinDateLimit.');
    }
  }
}

// DO follow API design principles
class TimeSlot({required this.start, required this.end}) {
  this : assert(start.isBefore(end), 'Start must be before end');

  final DateTime start;
  final DateTime end;
}

extension DateTimeExtension on DateTime {
  DateTime get addOneSecond => add(const Duration(seconds: 1));
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get subtractOneSecond => subtract(const Duration(seconds: 1));
  DateTime toSecondPrecision() =>
      DateTime(year, month, day, hour, minute, second);
}
