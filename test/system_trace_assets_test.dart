import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('system trace assets', () {
    for (final id in SystemTraceId.values) {
      final assetPath = 'assets/system_traces/${id.name}.json';

      test('$assetPath passes schema validation', () async {
        final raw = await rootBundle.loadString(assetPath);
        final json = jsonDecode(raw);

        expect(
          () => SystemTraceValidator.validate(
            fileName: '${id.name}.json',
            expectedId: id.name,
            json: json,
          ),
          returnsNormally,
          reason: 'Schema validation should pass for $assetPath',
        );

        final document = SystemTraceDocument.fromJson(json as Map<String, dynamic>);
        expect(document.id, id.name);
        expect(document.strokes, isNotEmpty);
      });
    }

    test('validator catches structure errors', () {
      final errors = SystemTraceValidator.collectErrors(
        fileName: 'broken.json',
        expectedId: 'broken',
        json: {
          'id': 'alert',
          'kind': 'system',
          'coordinateSpace': 'normalized',
          'fadeDurationMs': 2200,
          'strokes': [
            {
              'color': 'not-a-color',
              'points': [
                {'x': 0.1, 'y': 0.2},
              ],
            },
          ],
        },
      );

      expect(errors, isNotEmpty);
      expect(errors.join('\n'), contains('id must match the filename'));
      expect(errors.join('\n'), contains('color must match'));
      expect(errors.join('\n'), contains('at least 2 points'));
    });
  });
}
