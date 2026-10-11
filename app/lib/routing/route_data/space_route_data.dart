part of '../router.dart';

extension BuildContextSpace on BuildContext {
  void navigateToSpace(String mid, {String? source}) =>
      SpaceRouteData(mid: mid, source: source).push(this);
}

@TypedGoRoute<SpaceRouteData>(path: '${Routes.space}/:mid')
@immutable
class const SpaceRouteData({required final String mid, final String? source})
    extends GoRouteData
    with $SpaceRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = _resolveSource(context, explicitSource: source);
    if (effectiveSource == null) {
      return const NoMediaSourceScreen(message: '创作者所属的数据源不可用');
    }

    return ServiceSourceProviders(
      source: effectiveSource.id,
      child: SpaceScreen(mid: mid, onBackClick: () => context.pop()),
    );
  }
}
