import 'dart:convert';
import 'dart:io';

import 'package:tracelet/domain/system_traces/system_trace_id.dart';

/// Compares assets/system_traces/*.json against generator output.
///
/// Usage:
///   dart run tool/check_system_traces_diff.dart
///
/// Reports:
///   CUSTOM     hand-edited (differs from generator template)
///   GENERATED  matches generator exactly (safe to regenerate)
///   MANUAL     not managed by generator (bottleSent, etc.)
Future<void> main() async {
  final tempDir = await Directory.systemTemp.createTemp('tracelet-trace-diff-');
  try {
    final result = await Process.run(
      Platform.executable,
      [
        'run',
        'tool/generate_system_traces.dart',
        '--force',
        '--output-dir=${tempDir.path}',
      ],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      stderr.writeln(result.stdout);
      exitCode = 1;
      return;
    }

    const manualOnly = {'bottleSent', 'bottleDiscarded', 'bottleError'};
    var custom = 0;
    var generated = 0;
    var manual = 0;
    var missing = 0;

    for (final id in SystemTraceId.values) {
      final assetFile = File('assets/system_traces/${id.name}.json');
      if (!assetFile.existsSync()) {
        stderr.writeln('MISSING ${assetFile.path}');
        missing++;
        continue;
      }

      if (manualOnly.contains(id.name)) {
        stdout.writeln('MANUAL  ${assetFile.path}');
        manual++;
        continue;
      }

      final templateFile = File('${tempDir.path}/${id.name}.json');
      if (!templateFile.existsSync()) {
        stdout.writeln('CUSTOM  ${assetFile.path} (no generator template)');
        custom++;
        continue;
      }

      final current = jsonDecode(assetFile.readAsStringSync());
      final template = jsonDecode(templateFile.readAsStringSync());
      if (jsonEncode(current) == jsonEncode(template)) {
        stdout.writeln('GENERATED ${assetFile.path}');
        generated++;
      } else {
        stdout.writeln('CUSTOM  ${assetFile.path}');
        custom++;
      }
    }

    stdout.writeln(
      '\nSummary: $custom custom, $generated generator-template, '
      '$manual manual-only, $missing missing',
    );

    if (missing > 0) {
      exitCode = 1;
    }
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
