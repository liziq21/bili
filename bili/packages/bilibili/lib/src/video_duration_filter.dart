enum VideoDurationFilter {
  allDuration,
  below10Minutes,
  tenTo30Minutes,
  thirtyTo60Minutes,
  above60Minutes;

  @override
  String toString() => '$index';
}