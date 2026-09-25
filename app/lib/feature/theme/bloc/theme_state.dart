import 'package:model/model.dart';

class const ThemeState(
  final bool useDynamicColor,
  final ThemeConfig themeConfig,
) {
  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
      other.useDynamicColor == useDynamicColor &&
      other.themeConfig == themeConfig;

  @override
  int get hashCode => Object.hash(useDynamicColor, themeConfig);
}
