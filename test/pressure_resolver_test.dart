import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/input/pressure_input_detector.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/traces/pressure_resolver.dart';

TracePoint _point(
  double x,
  double y, {
  int ms = 0,
  double? pressure,
}) =>
    TracePoint(
      position: Offset(x, y),
      timestamp: DateTime.fromMillisecondsSinceEpoch(ms),
      pressure: pressure,
    );

void main() {
  group('PressureResolver', () {
    const config = TracePressureProfile(
      minPressure: 0.2,
      maxPressure: 1.0,
      startPressure: 0.85,
      speedSlowPxPerSec: 50,
      speedFastPxPerSec: 500,
    );

    test('uses hardware pressure when mode is hardware', () {
      final value = PressureResolver.resolve(
        config: config,
        inputMode: PressureInputMode.hardware,
        current: _point(1, 1),
        hardwarePressure: 0.5,
      );

      expect(value, closeTo(0.6, 0.001));
    });

    test('slow draw yields higher pressure in software mode', () {
      final current = _point(10, 10, ms: 100);
      final previous = _point(0, 0, ms: 0);

      final slow = PressureResolver.resolve(
        config: config,
        inputMode: PressureInputMode.software,
        current: current,
        previous: previous,
      );

      final fastCurrent = _point(500, 0, ms: 16);
      final fastPrevious = _point(0, 0, ms: 0);
      final fast = PressureResolver.resolve(
        config: config,
        inputMode: PressureInputMode.software,
        current: fastCurrent,
        previous: fastPrevious,
      );

      expect(slow, greaterThan(fast));
    });

    test('first point uses start pressure in software mode', () {
      final value = PressureResolver.resolve(
        config: config,
        inputMode: PressureInputMode.software,
        current: _point(1, 1),
      );

      expect(value, config.startPressure);
    });
  });
}
