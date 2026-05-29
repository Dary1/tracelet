import 'package:flutter/material.dart';

import 'package:tracelet/domain/input/pressure_input_detector.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/traces/pressure_resolver.dart';

/// Builds [TracePoint]s with resolved pressure at capture time.
class PressureCapture {
  PressureCapture({
    required this.detector,
    required this.profile,
  });

  final PressureInputDetector detector;
  final TracePressureProfile Function() profile;

  TracePoint buildPoint({
    required Offset position,
    required DateTime timestamp,
    required double hardwarePressure,
    TracePoint? previous,
    Color? color,
  }) {
    final config = profile();
    detector.observe(hardwarePressure);

    final draft = TracePoint(
      position: position,
      timestamp: timestamp,
      color: color,
    );
    final resolved = PressureResolver.resolve(
      config: config,
      inputMode: detector.mode,
      current: draft,
      previous: previous,
      hardwarePressure: hardwarePressure,
    );

    return draft.copyWith(pressure: resolved);
  }
}
