import 'package:material_ui/material_ui.dart';

class const Motion._() {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
  static const extraSlow = Duration(milliseconds: 500);

  /// Material 3 Easing Curves
  static const Curve easingEmphasized = Curves.easeInOutCubicEmphasized;
  static const Curve easingStandard = Curves.fastOutSlowIn;
  static const Curve easingDecelerate = Curves.easeOutCubic;
  static const Curve easingAccelerate = Curves.easeInCubic;
}
