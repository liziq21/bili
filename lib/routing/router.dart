import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:f_biuli/screens/home/home_screen.dart';
import 'package:f_biuli/screens/live/live_screen.dart';
import 'package:f_biuli/screens/not_found/not_found_screen.dart';
import 'package:f_biuli/screens/search/search_screen.dart';
import 'package:f_biuli/screens/space/space_screen.dart';
import 'package:f_biuli/screens/video/video_screen.dart';

import 'package:f_biuli/bili/bili_utils.dart';
import 'package:f_biuli/bili/routes.dart';

part 'route_data/home_route_data.dart';
part 'route_data/live_route_data.dart';
part 'route_data/not_found_route_data.dart';
part 'route_data/search_route_data.dart';
part 'route_data/space_route_data.dart';
part 'route_data/video_route_data.dart';
part 'router.g.dart';

final GoRouter router = GoRouter(
  onException: (_, GoRouterState state, GoRouter router) {
    final path = BiliUtils.getRoutePath(state.uri);
    if (path == null)  {
      router.go(Routes.notFound, extra: state.uri);
    } else {
      router.go(path);
      /*final uri = state.uri;
      router.go(
        Routes.notFound,
        extra: Uri(
          path: '/${uri.host}${uri.path}',
          queryParameters: uri.queryParametersAll.isEmpty ? null : uri.queryParametersAll,
          fragment: uri.fragment.isEmpty ? null : uri.fragment,
        ),
      );*/
    }
  },
  routes: $appRoutes,
  initialLocation: Routes.home,
  //redirect: (context, state) => BiliUtils.httpToRoutePath(state.uri),
);
