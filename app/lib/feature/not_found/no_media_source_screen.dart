import 'package:material_ui/material_ui.dart';

/// Shown when no registered source can satisfy a route.
class const NoMediaSourceScreen({
  super.key,
  final String message = '当前没有可用的数据源',
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据源不可用')),
      body: Center(child: Text(message)),
    );
  }
}
