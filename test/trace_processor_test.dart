import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/models/trace_coordinate_space.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/traces/trace_playback_mapper.dart';
import 'package:tracelet/domain/traces/trace_processor.dart';

void main() {
  group('TraceProcessor', () {
    test('pure finger normalizes coordinates to sender viewport', () {
      const captureSize = Size(400, 800);
      final raw = [
        TracePoint(
          position: const Offset(10, 20),
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        TracePoint(
          position: const Offset(30, 40),
          timestamp: DateTime.fromMillisecondsSinceEpoch(50),
        ),
      ];
      final out = TraceProcessor.process(
        raw: raw,
        profile: TraceProfilePresets.pureFinger,
        captureSize: captureSize,
      );

      expect(out, hasLength(2));
      expect(out[0].position.dx, closeTo(10 / 400, 0.001));
      expect(out[0].position.dy, closeTo(20 / 800, 0.001));
    });

    test('little prettify stores normalized coordinates', () {
      const captureSize = Size(400, 800);
      final raw = [
        TracePoint(
          position: const Offset(50, 100),
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        TracePoint(
          position: const Offset(150, 200),
          timestamp: DateTime.fromMillisecondsSinceEpoch(40),
        ),
      ];
      final out = TraceProcessor.process(
        raw: raw,
        profile: TraceProfilePresets.littlePrettify,
        captureSize: captureSize,
      );

      final drawable = out.where((p) => !p.isBreak).toList();
      expect(drawable, isNotEmpty);
      expect(drawable.first.position.dx, greaterThan(0.05));
      expect(drawable.first.position.dy, greaterThan(0.05));
      expect(drawable.last.position.dx, lessThan(0.5));
      expect(drawable.last.position.dy, lessThan(0.35));
    });
  });

  group('TracePlaybackMapper', () {
    const senderSize = Size(400, 800);
    final playback = TraceProfilePresets.pureFinger.toPlaybackProfile(senderSize);

    test('same-size receiver uses normalized coordinates 1:1', () {
      final mapped = TracePlaybackMapper.toCanvas(
        stored: const Offset(0.3, 0.5),
        playback: playback,
        canvasSize: senderSize,
      );

      expect(mapped.dx, closeTo(120, 0.5));
      expect(mapped.dy, closeTo(400, 0.5));
    });

    test('larger receiver preserves relative position and uniform scale', () {
      final mapped = TracePlaybackMapper.toCanvas(
        stored: const Offset(0.5, 0.5),
        playback: playback,
        canvasSize: const Size(800, 1600),
      );

      expect(mapped.dx / 800, closeTo(0.5, 0.02));
      expect(mapped.dy / 1600, closeTo(0.5, 0.02));
    });

    test('smaller receiver scales down uniformly', () {
      final mapped = TracePlaybackMapper.toCanvas(
        stored: const Offset(0.3, 0.3),
        playback: playback,
        canvasSize: const Size(200, 400),
      );

      expect(mapped.dx, closeTo(60, 0.5));
      expect(mapped.dy, closeTo(120, 0.5));
    });

    test('legacy absolute coords still map with letterboxing', () {
      final legacy = TracePlaybackProfile.fromLegacyPayload(
        preset: TraceProfilePresets.littlePrettify.preset,
        captureWidth: 400,
        captureHeight: 800,
        coordinateSpace: TraceCoordinateSpace.absolute,
        particles: TraceProfilePresets.littlePrettify.particles,
        pressure: TraceProfilePresets.littlePrettify.pressure,
      );
      final mapped = TracePlaybackMapper.toCanvas(
        stored: const Offset(200, 400),
        playback: legacy,
        canvasSize: const Size(200, 400),
      );

      expect(mapped.dx, closeTo(100, 1));
      expect(mapped.dy, closeTo(200, 1));
    });
  });
}
