import 'package:flutter/widgets.dart';

extension ColorFilterOnColor on Color {
  ColorFilter get colorFilter => ColorFilter.mode(this, BlendMode.srcIn);
}
