import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';

/// Prints fixture/schema fingerprints for one or more JSON fixtures.
///
/// Run from `packages/bilibili`:
///
/// ```text
/// dart run tool/mapping_fingerprint.dart bpi/testing/popular.json
/// ```
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/mapping_fingerprint.dart <fixture>...',
    );
    exitCode = 2;
    return;
  }

  for (final path in args) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Missing fixture: $path');
      exitCode = 1;
      continue;
    }
    final value = jsonDecode(file.readAsStringSync());
    final fingerprint = fingerprintJson(value);
    stdout.writeln(path);
    stdout.writeln('  fixtureHash: ${fingerprint.fixtureHash}');
    stdout.writeln('  sourceSchemaHash: ${fingerprint.sourceSchemaHash}');
  }
}
