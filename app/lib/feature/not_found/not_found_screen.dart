import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    super.key,
    required this.uri,
    required this.path,
  });

  final String uri;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(child: Text("Can't find a page for: $uri \n Path: $path")),
    );
  }
}