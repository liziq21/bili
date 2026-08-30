import 'package:material_ui/material_ui.dart';

class const CenteredBox({
  super.key,
  required final Widget child,
  final double? width,
  final double? height,
  final EdgeInsets? padding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? EdgeInsets.zero,
    child: Center(
      child: SizedBox(width: width, height: height, child: child),
    ),
  );
}
