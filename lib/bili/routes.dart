
abstract final class Routes {
  static const notFound = '/404';
  static const home = '/';
  static const live = '/${liveRelative}';
  static const liveRelative = 'live';
  static const search = '/${searchRelative}';
  static const searchRelative = 'search';
  static const space = '/${spaceRelative}';
  static const spaceRelative  = 'space';
  static const video = '/${videoRelative}';
  static const videoRelative = 'video';
  
  static String videoWithId(String id) => '$video/$id';
}