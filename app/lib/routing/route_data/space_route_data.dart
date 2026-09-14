part of '../router.dart';

extension BuildContextSpace on BuildContext {
  void navigateToSpace(String mid, {ServiceSource? source}) =>
      SpaceRouteData(mid: mid, source: source).push(this);
}

@TypedGoRoute<SpaceRouteData>(path: '${Routes.space}/:mid')
@immutable
class SpaceRouteData extends GoRouteData with $SpaceRouteData {
  const SpaceRouteData({required this.mid, this.source});

  final String mid;
  final ServiceSource? source;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = source ?? _resolveSource(context);

    return ServiceSourceProviders(
      source: effectiveSource,
      child: SpaceScreen(mid: mid, onBackClick: () => context.pop()),
    );
  }
}
