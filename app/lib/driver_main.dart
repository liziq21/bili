// Entry point that enables the Flutter Driver extension for UI inspection
// and automated testing via the Dart MCP tools.
//
// Run with: `flutter run -d linux --target=lib/driver_main.dart`
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';

import 'main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
