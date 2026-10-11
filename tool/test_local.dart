import 'dart:io';

const _flutterProbePath = '.dart_tool/bili_flutter_test_runner_probe.dart';

const _flutterProbeSource = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter test runner probe', () {
    expect(true, isTrue);
  });
}
''';

const _usage = '''Usage: dart run tool/test_local.dart [--require-flutter]

Runs the complete local test matrix when flutter_tester is available. When the
Flutter test runner cannot start because of a host-environment problem, runs
the pure Dart checks and reports the Flutter suites that CI must verify.

Options:
  --require-flutter  Fail instead of falling back when Flutter tests cannot run.
  --help             Show this help text.
''';

Future<void> main(List<String> args) async {
  exitCode = await runLocalTests(args);
}

Future<int> runLocalTests(List<String> args) async {
  final requireFlutter = args.contains('--require-flutter');
  final unknownArgs = args
      .where((arg) => arg != '--require-flutter' && arg != '--help')
      .toList();

  if (args.contains('--help')) {
    stdout.write(_usage);
    return unknownArgs.isEmpty ? 0 : 64;
  }
  if (unknownArgs.isNotEmpty) {
    stderr
      ..writeln('Unknown option(s): ${unknownArgs.join(', ')}')
      ..write(_usage);
    return 64;
  }

  final probe = await _probeFlutterRunner();
  if (probe.failed) {
    return probe.exitCode == 0 ? 1 : probe.exitCode;
  }

  if (probe.available) {
    stdout.writeln(
      'Flutter test runner is available; running the complete local matrix.',
    );
    return _runCompleteMatrix();
  }

  if (requireFlutter) {
    stderr.writeln(
      'Flutter test runner is unavailable. Re-run without --require-flutter '
      'to use the pure Dart fallback.',
    );
    return 1;
  }

  return _runPureDartFallback();
}

Future<int> _runCompleteMatrix() async {
  const suites = [
    (
      label: 'app Flutter tests',
      executable: 'flutter',
      arguments: ['test'],
      workingDirectory: 'app',
    ),
    (
      label: 'bilibili package tests',
      executable: 'flutter',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/bilibili',
    ),
    (
      label: 'bilibili API package tests',
      executable: 'dart',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/bilibili/bpi',
    ),
    (
      label: 'youtube package tests',
      executable: 'flutter',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/youtube',
    ),
    (
      label: 'youtube API package tests',
      executable: 'dart',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/youtube/ypi',
    ),
    (
      label: 'data package tests',
      executable: 'dart',
      arguments: ['test'],
      workingDirectory: 'packages/data',
    ),
  ];

  for (final suite in suites) {
    final result = await _runSuite(
      suite.label,
      suite.executable,
      suite.arguments,
      suite.workingDirectory,
    );
    if (result != 0) return result;
  }
  return 0;
}

Future<int> _runPureDartFallback() async {
  stderr.writeln(
    'Flutter test runner is unavailable in this environment. '
    'Running pure Dart checks; Flutter suites remain required in CI.',
  );

  const suites = [
    (
      label: 'bilibili API package tests',
      executable: 'dart',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/bilibili/bpi',
    ),
    (
      label: 'youtube API package tests',
      executable: 'dart',
      arguments: ['test', 'test/'],
      workingDirectory: 'packages/youtube/ypi',
    ),
    (
      label: 'data package tests',
      executable: 'dart',
      arguments: ['test'],
      workingDirectory: 'packages/data',
    ),
    (
      label: 'model package analysis (no test directory)',
      executable: 'dart',
      arguments: ['analyze'],
      workingDirectory: 'packages/model',
    ),
  ];

  for (final suite in suites) {
    final result = await _runSuite(
      suite.label,
      suite.executable,
      suite.arguments,
      suite.workingDirectory,
    );
    if (result != 0) return result;
  }

  stderr.writeln(
    'Fallback checks passed. Flutter widget, golden, and Flutter-package '
    'tests were not run locally; CI must provide the complete result.',
  );
  return 0;
}

Future<({bool available, bool failed, int exitCode})>
_probeFlutterRunner() async {
  final probeFile = File('app/$_flutterProbePath');
  await probeFile.parent.create(recursive: true);
  await probeFile.writeAsString(_flutterProbeSource);

  try {
    final result = await _runCommand(
      'flutter',
      ['test', '--no-pub', _flutterProbePath],
      workingDirectory: 'app',
      writeOutput: false,
    );
    if (result.exitCode == 0) {
      return (available: true, failed: false, exitCode: 0);
    }

    final diagnostics = '${result.stdout}\n${result.stderr}';
    if (_isHostRunnerFailure(diagnostics)) {
      stderr.writeln(
        'Flutter runner probe failed because the host environment cannot '
        'start the Flutter test process:',
      );
      stderr.write(result.stderr);
      return (available: false, failed: false, exitCode: result.exitCode);
    }

    stdout.write(result.stdout);
    stderr.write(result.stderr);
    stderr.writeln('Flutter runner probe failed for a test or project error.');
    return (available: false, failed: true, exitCode: result.exitCode);
  } finally {
    try {
      if (probeFile.existsSync()) await probeFile.delete();
    } on FileSystemException catch (error) {
      stderr.writeln('Unable to remove temporary Flutter probe: $error');
    }
  }
}

bool _isHostRunnerFailure(String diagnostics) {
  const markers = [
    'CANNOT LINK EXECUTABLE',
    'libvk_swiftshader.so',
    'error while loading shared libraries',
    'failed to start flutter_tester',
    'bad interpreter',
    'ProcessException',
  ];
  return markers.any(diagnostics.contains);
}

Future<int> _runSuite(
  String label,
  String executable,
  List<String> arguments,
  String workingDirectory,
) async {
  stdout.writeln('\n==> $label');
  final result = await _runCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode == 0) return 0;

  stderr.writeln('Suite failed: $label (exit code ${result.exitCode}).');
  return result.exitCode;
}

Future<({int exitCode, String stdout, String stderr})> _runCommand(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  bool writeOutput = true,
}) async {
  final command = executable == 'dart' ? _resolveDartExecutable() : executable;
  try {
    final result = await Process.run(
      command,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    final commandResult = (
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
    if (writeOutput) {
      stdout.write(commandResult.stdout);
      stderr.write(commandResult.stderr);
    }
    return commandResult;
  } on ProcessException catch (error) {
    final commandResult = (exitCode: 127, stdout: '', stderr: '$error\n');
    if (writeOutput) stderr.write(commandResult.stderr);
    return commandResult;
  }
}

String _resolveDartExecutable() {
  final configured = Platform.environment['DART_EXECUTABLE'];
  if (configured != null && configured.isNotEmpty) return configured;

  // In a JIT invocation, resolvedExecutable points at the SDK Dart binary,
  // which avoids a broken `dart` shim on environments such as Termux. An AOT
  // executable has a different basename, so it falls back to PATH instead of
  // recursively starting itself.
  final current = Platform.resolvedExecutable;
  if (current.endsWith('/dart') || current.endsWith(r'\dart.exe')) {
    return current;
  }
  return Platform.isWindows ? 'dart.exe' : 'dart';
}
