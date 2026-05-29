import 'dart:convert';
import 'dart:io';

import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_paths.dart';
import 'package:tracelet/domain/system_traces/system_trace_theme_id.dart';

/// Compares assets/system_traces/<theme>/*.json against generator output.
///
/// Usage:
///   dart run tool/check_system_traces_diff.dart
///   dart run tool/check_system_traces_diff.dart --theme=default
///
/// Reports:
///   CUSTOM     hand-edited (differs from generator template)
///   GENERATED  matches generator exactly (safe to regenerate)
///   MANUAL     not managed by generator (bottleSent, etc.)
Future<void> main(List<String> args) async {
  final themeArg = _argValue(args, '--theme=') ?? 'default';
  final tempDir = await Directory.systemTemp.createTemp('tracelet-trace-diff-');
  try {
    final result = await Process.run(
      Platform.executable,
      [
        'run',
        'tool/generate_system_traces.dart',
        '--force',
        '--theme=$themeArg',
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
      final assetFile = File(
        SystemTracePaths.assetPath(
          SystemTraceThemeId.values.firstWhere(
            (theme) => theme.folderName == themeArg,
            orElse: () => SystemTraceThemeId.defaultTheme,
          ),
          id,
        ),
      );
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

String? _argValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
  }
  return null;
}
