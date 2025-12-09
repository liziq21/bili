// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRouteData,
  $liveRouteData,
  $notFoundRouteData,
  $searchRouteData,
  $spaceRouteData,
  $videoRouteData,
];

RouteBase get $homeRouteData =>
    GoRouteData.$route(path: '/', factory: $HomeRouteData._fromState);

mixin $HomeRouteData on GoRouteData {
  static HomeRouteData _fromState(GoRouterState state) => const HomeRouteData();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $liveRouteData => GoRouteData.$route(
  path: '/live/:roomId',
  factory: $LiveRouteData._fromState,
);

mixin $LiveRouteData on GoRouteData {
  static LiveRouteData _fromState(GoRouterState state) =>
      LiveRouteData(roomId: state.pathParameters['roomId']!);

  LiveRouteData get _self => this as LiveRouteData;

  @override
  String get location =>
      GoRouteData.$location('/live/${Uri.encodeComponent(_self.roomId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notFoundRouteData =>
    GoRouteData.$route(path: '/404', factory: $NotFoundRouteData._fromState);

mixin $NotFoundRouteData on GoRouteData {
  static NotFoundRouteData _fromState(GoRouterState state) =>
      const NotFoundRouteData();

  @override
  String get location => GoRouteData.$location('/404');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $searchRouteData =>
    GoRouteData.$route(path: '/search', factory: $SearchRouteData._fromState);

mixin $SearchRouteData on GoRouteData {
  static SearchRouteData _fromState(GoRouterState state) =>
      SearchRouteData(state.uri.queryParameters['keyword']);

  SearchRouteData get _self => this as SearchRouteData;

  @override
  String get location => GoRouteData.$location(
    '/search',
    queryParams: {if (_self.keyword != null) 'keyword': _self.keyword},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $spaceRouteData => GoRouteData.$route(
  path: '/space/:mid',
  factory: $SpaceRouteData._fromState,
);

mixin $SpaceRouteData on GoRouteData {
  static SpaceRouteData _fromState(GoRouterState state) =>
      SpaceRouteData(mid: state.pathParameters['mid']!);

  SpaceRouteData get _self => this as SpaceRouteData;

  @override
  String get location =>
      GoRouteData.$location('/space/${Uri.encodeComponent(_self.mid)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $videoRouteData =>
    GoRouteData.$route(path: '/video/:id', factory: $VideoRouteData._fromState);

mixin $VideoRouteData on GoRouteData {
  static VideoRouteData _fromState(GoRouterState state) => VideoRouteData(
    id: state.pathParameters['id']!,
    cid: state.uri.queryParameters['cid'],
    comment_root_id: state.uri.queryParameters['comment_root_id'],
    comment_secondary_id: state.uri.queryParameters['comment_secondary_id'],
    dm_progress: state.uri.queryParameters['dm_progress'],
  );

  VideoRouteData get _self => this as VideoRouteData;

  @override
  String get location => GoRouteData.$location(
    '/video/${Uri.encodeComponent(_self.id)}',
    queryParams: {
      if (_self.cid != null) 'cid': _self.cid,
      if (_self.comment_root_id != null)
        'comment_root_id': _self.comment_root_id,
      if (_self.comment_secondary_id != null)
        'comment_secondary_id': _self.comment_secondary_id,
      if (_self.dm_progress != null) 'dm_progress': _self.dm_progress,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
