part of '../router.dart';

@TypedGoRoute<NotFoundRouteData>(path: Routes.notFound)
@immutable
class NotFoundRouteData extends GoRouteData with $NotFoundRouteData {
  const NotFoundRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final uri = state.extra as Uri?;
    return NotFoundScreen(
      uri: uri.toString(),
      path: "${uri?.path ?? ''}\nHost: ${uri?.host ?? ''}\nScheme: ${uri?.scheme ?? ''}"
    );
  }
}