import 'package:model/model.dart';

class ThemeState {
  const ThemeState(this.useDynamicColor, this.themeConfig);

  final bool useDynamicColor;
  final ThemeConfig themeConfig;

  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
      other.useDynamicColor == useDynamicColor &&
      other.themeConfig == themeConfig;

  @override
  int get hashCode => Object.hash(useDynamicColor, themeConfig);
}
