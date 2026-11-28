part of '../router.dart';

@TypedGoRoute<NotFoundRouteData>(path: Routes.notFound)
@immutable
class const NotFoundRouteData() extends GoRouteData with $NotFoundRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final uri = state.extra as Uri?;
    final l10n = AppLocalizations.of(context)!;
    return NotFoundScreen(
      l10n: l10n,
      uri: uri.toString(),
      path:
          "${uri?.path ?? ''}\nHost: ${uri?.host ?? ''}\nScheme: ${uri?.scheme ?? ''}",
    );
  }
}
