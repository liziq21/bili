import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';

/// Scores candidate canonical items against a golden array.
///
/// Run from `packages/bilibili`:
///
/// ```text
/// dart run tool/mapping_eval.dart \
///   --golden test/fixtures/declarative/popular.json \
///   --candidate /tmp/popular-candidate.json
/// ```
///
/// The candidate may come from any model or prompt. The tool never calls a
/// model; it only scores deterministic output and prints a JSON report.
void main(List<String> args) {
  final goldenPath = _option(args, '--golden');
  final candidatePath = _option(args, '--candidate');
  final failOnDiff = args.contains('--fail-on-diff');
  if (goldenPath == null || candidatePath == null) {
    stderr.writeln(
      'Usage: dart run tool/mapping_eval.dart '
      '--golden <golden.json> --candidate <candidate.json> [--fail-on-diff]',
    );
    exitCode = 2;
    return;
  }

  final expected = _readItems(goldenPath);
  final actual = _readItems(candidatePath);
  final report = evaluateMappingCandidates(expected: expected, actual: actual);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  if (failOnDiff && !report.passes) {
    exitCode = 1;
  }
}

List<Map<String, Object?>> _readItems(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('JSON file not found', path);
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) {
    throw FormatException('Expected a JSON array: $path');
  }
  final items = <Map<String, Object?>>[];
  for (final item in decoded) {
    if (item is! Map) {
      throw FormatException('Expected object items in $path');
    }
    items.add(item.cast<String, Object?>());
  }
  return items;
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
