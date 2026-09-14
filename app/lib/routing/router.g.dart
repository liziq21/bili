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

RouteBase get $homeRouteData => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $HomeRouteData._fromState,
);

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
  hasOverriddenOnExit: false,
  factory: $LiveRouteData._fromState,
);

mixin $LiveRouteData on GoRouteData {
  static LiveRouteData _fromState(GoRouterState state) => LiveRouteData(
    roomId: state.pathParameters['roomId']!,
    source: _$convertMapValue(
      'source',
      state.uri.queryParameters,
      _$ServiceSourceEnumMap._$fromName,
    ),
  );

  LiveRouteData get _self => this as LiveRouteData;

  @override
  String get location => GoRouteData.$location(
    '/live/${Uri.encodeComponent(_self.roomId)}',
    queryParams: {
      if (_self.source != null) 'source': _$ServiceSourceEnumMap[_self.source!],
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

const _$ServiceSourceEnumMap = {
  ServiceSource.bilibili: 'bilibili',
  ServiceSource.youtube: 'youtube',
};

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}

RouteBase get $notFoundRouteData => GoRouteData.$route(
  path: '/404',
  hasOverriddenOnExit: false,
  factory: $NotFoundRouteData._fromState,
);

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

RouteBase get $searchRouteData => GoRouteData.$route(
  path: '/search',
  hasOverriddenOnExit: false,
  factory: $SearchRouteData._fromState,
);

mixin $SearchRouteData on GoRouteData {
  static SearchRouteData _fromState(GoRouterState state) => SearchRouteData(
    keyword: state.uri.queryParameters['keyword']!,
    source: _$convertMapValue(
      'source',
      state.uri.queryParameters,
      _$ServiceSourceEnumMap._$fromName,
    ),
  );

  SearchRouteData get _self => this as SearchRouteData;

  @override
  String get location => GoRouteData.$location(
    '/search',
    queryParams: {
      'keyword': _self.keyword,
      if (_self.source != null) 'source': _$ServiceSourceEnumMap[_self.source!],
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

RouteBase get $spaceRouteData => GoRouteData.$route(
  path: '/space/:mid',
  hasOverriddenOnExit: false,
  factory: $SpaceRouteData._fromState,
);

mixin $SpaceRouteData on GoRouteData {
  static SpaceRouteData _fromState(GoRouterState state) => SpaceRouteData(
    mid: state.pathParameters['mid']!,
    source: _$convertMapValue(
      'source',
      state.uri.queryParameters,
      _$ServiceSourceEnumMap._$fromName,
    ),
  );

  SpaceRouteData get _self => this as SpaceRouteData;

  @override
  String get location => GoRouteData.$location(
    '/space/${Uri.encodeComponent(_self.mid)}',
    queryParams: {
      if (_self.source != null) 'source': _$ServiceSourceEnumMap[_self.source!],
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

RouteBase get $videoRouteData => GoRouteData.$route(
  path: '/video/:id',
  hasOverriddenOnExit: false,
  factory: $VideoRouteData._fromState,
);

mixin $VideoRouteData on GoRouteData {
  static VideoRouteData _fromState(GoRouterState state) => VideoRouteData(
    id: state.pathParameters['id']!,
    source: _$convertMapValue(
      'source',
      state.uri.queryParameters,
      _$ServiceSourceEnumMap._$fromName,
    ),
    cid: state.uri.queryParameters['cid'],
    commentRootId: state.uri.queryParameters['comment-root-id'],
    commentSecondaryId: state.uri.queryParameters['comment-secondary-id'],
    dmProgress: state.uri.queryParameters['dm-progress'],
  );

  VideoRouteData get _self => this as VideoRouteData;

  @override
  String get location => GoRouteData.$location(
    '/video/${Uri.encodeComponent(_self.id)}',
    queryParams: {
      if (_self.source != null) 'source': _$ServiceSourceEnumMap[_self.source!],
      if (_self.cid != null) 'cid': _self.cid,
      if (_self.commentRootId != null) 'comment-root-id': _self.commentRootId,
      if (_self.commentSecondaryId != null)
        'comment-secondary-id': _self.commentSecondaryId,
      if (_self.dmProgress != null) 'dm-progress': _self.dmProgress,
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
