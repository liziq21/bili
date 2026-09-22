import 'package:data/data.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app_scaffold.dart';
import '../data/repository/search_contents_repository.dart';
import '../data/repository/search_suggest_repository.dart';
import '../data/repository/video_detail_repository.dart';
import '../feature/home/bloc/home_bloc.dart';
import '../feature/search/bloc/search_bloc.dart';
import '../feature/search/bloc/search_result_bloc.dart';
import '../providers/service_source_providers.dart';
import 'routes.dart';
import '../feature/home/home_screen.dart';
import '../feature/live/live_screen.dart';
import '../feature/not_found/not_found_screen.dart';
import '../feature/search/search_result_screen.dart';
import '../feature/space/space_screen.dart';
import '../feature/video/video_screen.dart';

part 'route_data/home_route_data.dart';
part 'route_data/live_route_data.dart';
part 'route_data/not_found_route_data.dart';
part 'route_data/search_result_route_data.dart';
part 'route_data/space_route_data.dart';
part 'route_data/video_route_data.dart';
part 'router.g.dart';

String _resolveSource(BuildContext context) {
  try {
    final s = context.read<String?>();
    if (s != null) return s;
  } catch (_) {}
  return 'bilibili';
}

final GoRouter router = GoRouter(
  // Security Hardening: Restrict diagnostic logging to non-release builds
  // to prevent leaking internal navigation traces, deep-link queries, and UI parameters.
  debugLogDiagnostics: !kReleaseMode,
  onException: (_, GoRouterState state, GoRouter router) {},
  routes: [
    ShellRoute(
      builder: (_, _, navigator) {
        return AppScaffold(child: navigator);
      },
      routes: $appRoutes,
    ),
  ],
  initialLocation: Routes.home,
);
