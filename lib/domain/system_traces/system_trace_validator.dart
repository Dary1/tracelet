import 'package:tracelet/domain/system_traces/system_trace_id.dart';

class SystemTraceValidationException implements Exception {
  SystemTraceValidationException(this.fileName, this.errors);

  final String fileName;
  final List<String> errors;

  @override
  String toString() {
    final buffer = StringBuffer('System trace validation failed: $fileName\n');
    for (final error in errors) {
      buffer.writeln('  • $error');
    }
    return buffer.toString().trimRight();
  }
}

/// Validates JSON structure for assets/system_traces/*.json before parsing.
abstract final class SystemTraceValidator {
  static const _hexColorPattern = r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$';
  static final _hexColorRegex = RegExp(_hexColorPattern);

  static const validIds = SystemTraceId.values;

  static void validate({
    required String fileName,
    required String expectedId,
    required Object? json,
  }) {
    final errors = collectErrors(
      fileName: fileName,
      expectedId: expectedId,
      json: json,
    );
    if (errors.isNotEmpty) {
      throw SystemTraceValidationException(fileName, errors);
    }
  }

  static List<String> collectErrors({
    required String fileName,
    required String expectedId,
    required Object? json,
  }) {
    final errors = <String>[];

    if (json is! Map) {
      errors.add('Root value must be a JSON object.');
      return errors;
    }

    _checkObject(
      json,
      path: r'$',
      allowedKeys: const {'id', 'kind', 'coordinateSpace', 'fadeDurationMs', 'strokes'},
      requiredKeys: const {'id', 'kind', 'coordinateSpace', 'fadeDurationMs', 'strokes'},
      errors: errors,
    );

    final id = json['id'];
    if (id is! String || id.isEmpty) {
      errors.add(r'$.id must be a non-empty string.');
    } else {
      if (id != expectedId) {
        errors.add(
          r'$.id must match the filename: expected "$expectedId", got "$id".',
        );
      }
      if (!validIds.any((value) => value.name == id)) {
        errors.add(r'$.id "$id" is not a known SystemTraceId.');
      }
    }

    final kind = json['kind'];
    if (kind is! String) {
      errors.add(r'$.kind must be the string "system".');
    } else if (kind != 'system') {
      errors.add(r'$.kind must be "system", got "$kind".');
    }

    final coordinateSpace = json['coordinateSpace'];
    if (coordinateSpace is! String) {
      errors.add(r'$.coordinateSpace must be the string "normalized".');
    } else if (coordinateSpace != 'normalized') {
      errors.add(
        r'$.coordinateSpace must be "normalized", got "$coordinateSpace".',
      );
    }

    final fadeDurationMs = json['fadeDurationMs'];
    if (fadeDurationMs is! num || fadeDurationMs != fadeDurationMs.round()) {
      errors.add(r'$.fadeDurationMs must be an integer.');
    } else if (fadeDurationMs < 1 || fadeDurationMs > 30000) {
      errors.add(r'$.fadeDurationMs must be between 1 and 30000.');
    }

    final strokes = json['strokes'];
    if (strokes is! List) {
      errors.add(r'$.strokes must be an array.');
      return errors;
    }
    if (strokes.isEmpty) {
      errors.add(r'$.strokes must contain at least one stroke.');
      return errors;
    }

    for (var i = 0; i < strokes.length; i++) {
      _validateStroke(
        strokes[i],
        path: '\$.strokes[$i]',
        coordinateSpace: coordinateSpace is String ? coordinateSpace : 'normalized',
        errors: errors,
      );
    }

    return errors;
  }

  static void _validateStroke(
    Object? stroke,
    {required String path,
    required String coordinateSpace,
    required List<String> errors,
  }) {
    if (stroke is! Map) {
      errors.add('$path must be an object.');
      return;
    }

    _checkObject(
      stroke,
      path: path,
      allowedKeys: const {'color', 'opacity', 'points'},
      requiredKeys: const {'points'},
      errors: errors,
    );

    final color = stroke['color'];
    if (color != null) {
      if (color is! String || !_hexColorRegex.hasMatch(color)) {
        errors.add(
          '$path.color must match #RRGGBB or #AARRGGBB, got "$color".',
        );
      }
    }

    final opacity = stroke['opacity'];
    if (opacity != null) {
      if (opacity is! num) {
        errors.add('$path.opacity must be a number between 0 and 1.');
      } else if (opacity < 0 || opacity > 1) {
        errors.add('$path.opacity must be between 0 and 1, got $opacity.');
      }
    }

    final points = stroke['points'];
    if (points is! List) {
      errors.add('$path.points must be an array.');
      return;
    }
    if (points.length < 2) {
      errors.add('$path.points must contain at least 2 points.');
      return;
    }

    for (var i = 0; i < points.length; i++) {
      _validatePoint(
        points[i],
        path: '$path.points[$i]',
        coordinateSpace: coordinateSpace,
        errors: errors,
      );
    }
  }

  static void _validatePoint(
    Object? point,
    {required String path,
    required String coordinateSpace,
    required List<String> errors,
  }) {
    if (point is! Map) {
      errors.add('$path must be an object.');
      return;
    }

    _checkObject(
      point,
      path: path,
      allowedKeys: const {'x', 'y', 't'},
      requiredKeys: const {'x', 'y'},
      errors: errors,
    );

    final x = point['x'];
    if (x is! num) {
      errors.add('$path.x must be a number.');
    } else if (coordinateSpace == 'normalized' && (x < 0 || x > 1)) {
      errors.add('$path.x must be between 0 and 1 for normalized traces, got $x.');
    }

    final y = point['y'];
    if (y is! num) {
      errors.add('$path.y must be a number.');
    } else if (coordinateSpace == 'normalized' && (y < 0 || y > 1)) {
      errors.add('$path.y must be between 0 and 1 for normalized traces, got $y.');
    }

    final t = point['t'];
    if (t != null) {
      if (t is! num || t != t.round() || t < 0) {
        errors.add('$path.t must be a non-negative integer.');
      }
    }
  }

  static void _checkObject(
    Map<dynamic, dynamic> object,
    {required String path,
    required Set<String> allowedKeys,
    required Set<String> requiredKeys,
    required List<String> errors,
  }) {
    for (final key in requiredKeys) {
      if (!object.containsKey(key)) {
        errors.add('$path.$key is required.');
      }
    }

    for (final key in object.keys) {
      if (key is! String) {
        errors.add('$path contains a non-string property name.');
        continue;
      }
      if (!allowedKeys.contains(key)) {
        errors.add('$path.$key is not allowed.');
      }
    }
  }
}
