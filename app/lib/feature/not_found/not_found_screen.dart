import 'package:material_ui/material_ui.dart';

class const NotFoundScreen({
  super.key,
  required final String uri,
  required final String path,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(child: Text("Can't find a page for: $uri \n Path: $path")),
    );
  }
}
