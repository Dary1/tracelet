import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Generates assets/system_traces/*.json from procedural definitions.
///
/// By default existing JSON files are NOT overwritten (hand-edited traces stay).
/// Use `--force` to regenerate every file, or `--only=id1,id2` for specific ids.
///
/// Examples:
///   dart run tool/generate_system_traces.dart
///   dart run tool/generate_system_traces.dart --only=noMessageFound
///   dart run tool/generate_system_traces.dart --force
///   dart run tool/generate_system_traces.dart --force --output-dir=build/generated_traces
void main(List<String> args) {
  final force = args.contains('--force');
  final onlyArg = _argValue(args, '--only=');
  final outputDirArg = _argValue(args, '--output-dir=');
  final onlyIds = onlyArg == null
      ? null
      : onlyArg.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty);

  final outputDir = Directory(outputDirArg ?? 'assets/system_traces');
  outputDir.createSync(recursive: true);

  final traces = <String, Map<String, dynamic>>{
    'modeMessageReceive': _doc(
      id: 'modeMessageReceive',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#007AFF', _line(0.18, 0.42, 0.82, 0.42, 24)),
        _stroke('#007AFF', [
          _pt(0.82, 0.42),
          _pt(0.76, 0.48),
          _pt(0.82, 0.54),
        ]),
        _stroke('#007AFF', _line(0.22, 0.48, 0.78, 0.48, 16), opacity: 0.7),
      ],
    ),
    'modeBottleMail': _doc(
      id: 'modeBottleMail',
      fadeDurationMs: 2200,
      strokes: [_stroke('#007AFF', _loop(36))],
    ),
    'modeSpecificUserSend': _doc(
      id: 'modeSpecificUserSend',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#007AFF', _line(0.5, 0.28, 0.5, 0.62, 20)),
        _stroke('#007AFF', _circle(0.5, 0.24, 0.035, 16)),
        _stroke('#007AFF', _line(0.38, 0.62, 0.62, 0.62, 12), opacity: 0.65),
      ],
    ),
    'notificationsOn': _doc(
      id: 'notificationsOn',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#007AFF', [_pt(0.42, 0.44), _pt(0.5, 0.38), _pt(0.58, 0.44)]),
      ],
    ),
    'notificationsOff': _doc(
      id: 'notificationsOff',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#007AFF', [_pt(0.42, 0.38), _pt(0.5, 0.44), _pt(0.58, 0.38)]),
        _stroke('#007AFF', _line(0.4, 0.41, 0.6, 0.41, 10), opacity: 0.7),
      ],
    ),
    'autoPlayOn': _doc(
      id: 'autoPlayOn',
      fadeDurationMs: 2200,
      strokes: [_stroke('#34C759', _arcLoop(closed: true))],
    ),
    'autoPlayOff': _doc(
      id: 'autoPlayOff',
      fadeDurationMs: 2200,
      strokes: [_stroke('#34C759', _arcLoop(closed: false))],
    ),
    'messagePlayback': _doc(
      id: 'messagePlayback',
      fadeDurationMs: 1500,
      strokes: [_stroke('#FFFFFF', _wave())],
    ),
    'replayMessage': _doc(
      id: 'replayMessage',
      fadeDurationMs: 1500,
      strokes: [_stroke('#FFFFFF', _wave())],
    ),
    'randomMessage': _doc(
      id: 'randomMessage',
      fadeDurationMs: 1500,
      strokes: [
        _stroke('#34C759', _wave()),
        _stroke('#34C759', _circle(0.5, 0.24, 0.05, 18), opacity: 0.55),
      ],
    ),
    'friendConnected': _doc(
      id: 'friendConnected',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#34C759', _circle(0.34, 0.42, 0.03, 14)),
        _stroke('#34C759', _circle(0.66, 0.42, 0.03, 14)),
        _stroke('#34C759', _bridgeArc()),
      ],
    ),
    'friendUnavailable': _doc(
      id: 'friendUnavailable',
      fadeDurationMs: 2200,
      strokes: [_stroke('#FFFFFF', _circle(0.5, 0.4, 0.045, 18), opacity: 0.54)],
    ),
    'destinationSelected': _doc(
      id: 'destinationSelected',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#34C759', _circle(0.5, 0.36, 0.08, 24)),
        _stroke('#34C759', _line(0.36, 0.5, 0.64, 0.5, 14)),
        _stroke('#34C759', _line(0.42, 0.56, 0.58, 0.56, 8), opacity: 0.6),
      ],
    ),
    'nameTraceRegistrationPrompt': _doc(
      id: 'nameTraceRegistrationPrompt',
      fadeDurationMs: 3500,
      strokes: [
        _stroke('#007AFF', [
          _pt(0.14, 0.22),
          _pt(0.86, 0.22),
          _pt(0.86, 0.58),
          _pt(0.14, 0.58),
          _pt(0.14, 0.22),
        ], opacity: 0.85),
        _stroke('#FFFFFF', _guideWave(), opacity: 0.75),
        _stroke('#007AFF', _line(0.5, 0.62, 0.5, 0.68, 6), opacity: 0.5),
      ],
    ),
    'nameTraceSaved': _doc(
      id: 'nameTraceSaved',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#007AFF', [_pt(0.42, 0.44), _pt(0.48, 0.52), _pt(0.62, 0.34)]),
      ],
    ),
    'nameTraceSaveFailed': _doc(
      id: 'nameTraceSaveFailed',
      fadeDurationMs: 2200,
      strokes: [_stroke('#007AFF', _circle(0.5, 0.4, 0.045, 18))],
    ),
    'senderRemoved': _doc(
      id: 'senderRemoved',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#FFFFFF', _line(0.44, 0.36, 0.56, 0.48, 8), opacity: 0.7),
        _stroke('#FFFFFF', _line(0.56, 0.36, 0.44, 0.48, 8), opacity: 0.7),
      ],
    ),
    'autoContinuousOn': _doc(
      id: 'autoContinuousOn',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#34C759', _doubleWave(upper: true)),
        _stroke('#34C759', _doubleWave(upper: false), opacity: 0.7),
      ],
    ),
    'autoContinuousOff': _doc(
      id: 'autoContinuousOff',
      fadeDurationMs: 2200,
      strokes: [_stroke('#34C759', _line(0.24, 0.42, 0.76, 0.42, 18))],
    ),
    'settingsPortal': _doc(
      id: 'settingsPortal',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#FFFFFF', [
          _pt(0.1, 0.14),
          _pt(0.9, 0.14),
          _pt(0.9, 0.78),
          _pt(0.1, 0.78),
          _pt(0.1, 0.14),
        ], opacity: 0.7),
      ],
    ),
    'alert': _doc(
      id: 'alert',
      fadeDurationMs: 2200,
      strokes: [_stroke('#FFFFFF', _circle(0.5, 0.4, 0.045, 18), opacity: 0.54)],
    ),
    'noMessageFound': _doc(
      id: 'noMessageFound',
      fadeDurationMs: 2200,
      strokes: [
        _stroke('#FFFFFF', _line(0.22, 0.42, 0.42, 0.42, 10), opacity: 0.6),
        _stroke('#FFFFFF', _line(0.58, 0.42, 0.78, 0.42, 10), opacity: 0.6),
        _stroke('#FFFFFF', _circle(0.5, 0.42, 0.025, 12), opacity: 0.45),
      ],
    ),
  };

  var wrote = 0;
  var skipped = 0;

  for (final entry in traces.entries) {
    if (onlyIds != null && !onlyIds.contains(entry.key)) {
      continue;
    }

    final file = File('${outputDir.path}/${entry.key}.json');
    if (!force && file.existsSync()) {
      skipped++;
      stdout.writeln('Skip ${file.path} (exists; use --force to overwrite)');
      continue;
    }

    final encoder = const JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(entry.value)}\n');
    wrote++;
    stdout.writeln('Wrote ${file.path}');
  }

  stdout.writeln('Done: $wrote written, $skipped skipped.');
}

String? _argValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
  }
  return null;
}

Map<String, dynamic> _doc({
  required String id,
  required int fadeDurationMs,
  required List<Map<String, dynamic>> strokes,
}) {
  return {
    'id': id,
    'kind': 'system',
    'coordinateSpace': 'normalized',
    'fadeDurationMs': fadeDurationMs,
    'strokes': strokes,
  };
}

Map<String, dynamic> _stroke(
  String color,
  List<Map<String, dynamic>> points, {
  double opacity = 1.0,
}) {
  return {
    'color': color,
    if (opacity != 1.0) 'opacity': opacity,
    'points': points,
  };
}

Map<String, dynamic> _pt(double x, double y, [int t = 0]) {
  if (t == 0) return {'x': _d(x), 'y': _d(y)};
  return {'x': _d(x), 'y': _d(y), 't': t};
}

double _d(double value) => double.parse(value.toStringAsFixed(4));

List<Map<String, dynamic>> _line(
  double x1,
  double y1,
  double x2,
  double y2,
  int steps,
) {
  return List.generate(steps + 1, (i) {
    final t = i / steps;
    return _pt(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
  });
}

List<Map<String, dynamic>> _circle(
  double cx,
  double cy,
  double radius,
  int steps,
) {
  return List.generate(steps + 1, (i) {
    final angle = (i / steps) * math.pi * 2;
    return _pt(
      cx + math.cos(angle) * radius,
      cy + math.sin(angle) * radius,
    );
  });
}

List<Map<String, dynamic>> _loop(int steps) {
  return List.generate(steps + 1, (i) {
    final t = i / steps;
    final angle = t * math.pi * 2;
    return _pt(
      0.5 + math.sin(angle) * 0.16,
      0.42 + math.cos(angle) * 0.1,
    );
  });
}

List<Map<String, dynamic>> _arcLoop({required bool closed}) {
  final steps = closed ? 32 : 24;
  return List.generate(steps + 1, (i) {
    final t = i / steps;
    final angle = -math.pi / 2 + t * math.pi * 1.65;
    return _pt(
      0.5 + math.cos(angle) * 0.12,
      0.42 + math.sin(angle) * 0.12,
    );
  });
}

List<Map<String, dynamic>> _wave() {
  return List.generate(41, (i) {
    final t = i / 40;
    return _pt(
      0.12 + t * 0.76,
      0.42 + math.sin(t * math.pi * 4) * 0.08,
    );
  });
}

List<Map<String, dynamic>> _bridgeArc() {
  return List.generate(19, (i) {
    final t = i / 18;
    final x = 0.34 + (0.66 - 0.34) * t;
    final y = 0.42 + math.sin(t * math.pi) * -0.12;
    return _pt(x, y);
  });
}

List<Map<String, dynamic>> _guideWave() {
  return List.generate(31, (i) {
    final t = i / 30;
    return _pt(0.2 + t * 0.6, 0.42 + math.sin(t * math.pi * 3) * 0.06);
  });
}

List<Map<String, dynamic>> _doubleWave({required bool upper}) {
  return List.generate(29, (i) {
    final t = i / 28;
    final yBase = upper ? 0.36 : 0.48;
    return _pt(
      0.18 + t * 0.64,
      yBase + math.sin(t * math.pi * 3) * 0.04,
    );
  });
}
