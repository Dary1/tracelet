import 'dart:math' as math;

import 'package:tracelet/domain/input/pressure_input_detector.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';

/// Resolves per-point pressure from hardware or draw speed.
abstract final class PressureResolver {
  static double resolve({
    required TracePressureProfile config,
    required PressureInputMode inputMode,
    required TracePoint current,
    TracePoint? previous,
    double? hardwarePressure,
  }) {
    if (!config.enabled) return 1.0;

    if (inputMode == PressureInputMode.hardware && hardwarePressure != null) {
      return _mapHardware(hardwarePressure, config);
    }

    return _fromDrawSpeed(
      current: current,
      previous: previous,
      config: config,
    );
  }

  static double _mapHardware(
    double hardwarePressure,
    TracePressureProfile config,
  ) {
    final normalized = hardwarePressure.clamp(0.0, 1.0);
    return config.minPressure +
        normalized * (config.maxPressure - config.minPressure);
  }

  static double _fromDrawSpeed({
    required TracePoint current,
    required TracePoint? previous,
    required TracePressureProfile config,
  }) {
    if (previous == null || previous.isBreak) {
      return config.startPressure.clamp(config.minPressure, config.maxPressure);
    }

    final dtMs = math.max(
      current.timestamp.difference(previous.timestamp).inMilliseconds,
      config.minSampleIntervalMs,
    );
    final dtSec = dtMs / 1000.0;
    final distance = (current.position - previous.position).distance;
    final speedPxPerSec = distance / dtSec;

    final span = math.max(config.speedFastPxPerSec - config.speedSlowPxPerSec, 1);
    final speedRatio =
        ((speedPxPerSec - config.speedSlowPxPerSec) / span).clamp(0.0, 1.0);

    // Slow strokes feel heavier; fast strokes feel lighter.
    final pressure =
        config.maxPressure - speedRatio * (config.maxPressure - config.minPressure);
    return pressure.clamp(config.minPressure, config.maxPressure);
  }
}
