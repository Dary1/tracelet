import 'dart:convert';
import 'dart:io';

import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_paths.dart';
import 'package:tracelet/domain/system_traces/system_trace_theme_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_validator.dart';

/// Validates syntax and structure of assets/system_traces/<theme>/*.json
///
/// Usage:
///   dart run tool/validate_system_traces.dart
///   dart run tool/validate_system_traces.dart assets/system_traces/default/modeSpecificUserSend.json
Future<void> main(List<String> args) async {
  final files = args.isEmpty
      ? [
          for (final theme in SystemTraceThemeId.values)
            for (final id in SystemTraceId.values)
              File(SystemTracePaths.assetPath(theme, id)),
        ]
      : args.map(File.new).toList();

  var failed = 0;

  for (final file in files) {
    if (!file.existsSync()) {
      stderr.writeln('MISSING ${file.path}');
      failed++;
      continue;
    }

    final fileName = file.uri.pathSegments.last;
    final expectedId = fileName.replaceAll('.json', '');

    try {
      final raw = file.readAsStringSync();
      final json = jsonDecode(raw);
      SystemTraceValidator.validate(
        fileName: fileName,
        expectedId: expectedId,
        json: json,
      );
      stdout.writeln('OK   ${file.path}');
    } on FormatException catch (error) {
      failed++;
      stderr.writeln('FAIL ${file.path}');
      stderr.writeln('  • Invalid JSON syntax: ${error.message}');
    } on SystemTraceValidationException catch (error) {
      failed++;
      stderr.writeln(error);
    }
  }

  if (failed > 0) {
    stderr.writeln('\n$failed file(s) failed validation.');
    exitCode = 1;
  } else {
    stdout.writeln('\nAll system trace JSON files are valid.');
  }
}
