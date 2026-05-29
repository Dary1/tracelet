import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';

/// Geometry-focused canvas capture for parity tests (ignores wall-clock timestamps).
class CanvasSnapshot {
  const CanvasSnapshot({
    required this.points,
    required this.pressureProfile,
    required this.particleStyle,
  });

  final List<RecordedCanvasPoint> points;
  final TracePressureProfile pressureProfile;
  final ParticleEffectStyle particleStyle;

  factory CanvasSnapshot.fromState(TraceCanvasState state) {
    return CanvasSnapshot(
      points: [
        for (final point in state.points) RecordedCanvasPoint.fromTracePoint(point),
      ],
      pressureProfile: state.pressureProfile,
      particleStyle: state.particleStyle,
    );
  }

  @override
  String toString() => 'CanvasSnapshot(points: ${points.length}, '
      'pressure: ${pressureProfile.minWidthPx}–${pressureProfile.maxWidthPx}, '
      'particles: $particleStyle)';
}

class RecordedCanvasPoint {
  const RecordedCanvasPoint({
    required this.isBreak,
    this.x = 0,
    this.y = 0,
    this.pressure = 1,
    this.colorArgb,
  });

  factory RecordedCanvasPoint.fromTracePoint(TracePoint point) {
    if (point.isBreak) {
      return const RecordedCanvasPoint(isBreak: true);
    }
    return RecordedCanvasPoint(
      isBreak: false,
      x: point.position.dx,
      y: point.position.dy,
      pressure: point.effectivePressure,
      colorArgb: point.color?.toARGB32(),
    );
  }

  final bool isBreak;
  final double x;
  final double y;
  final double pressure;
  final int? colorArgb;

  @override
  bool operator ==(Object other) {
    return other is RecordedCanvasPoint &&
        other.isBreak == isBreak &&
        _near(other.x, x) &&
        _near(other.y, y) &&
        _near(other.pressure, pressure) &&
        other.colorArgb == colorArgb;
  }

  @override
  int get hashCode => Object.hash(
        isBreak,
        _quantize(x),
        _quantize(y),
        _quantize(pressure),
        colorArgb,
      );

  @override
  String toString() {
    if (isBreak) return 'break';
    return '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}, p=${pressure.toStringAsFixed(2)})';
  }

  static bool _near(double a, double b) => (a - b).abs() < 0.05;

  static double _quantize(double value) => (value * 100).round() / 100;
}

bool canvasSnapshotsMatch(CanvasSnapshot a, CanvasSnapshot b) {
  if (a.particleStyle != b.particleStyle) return false;
  if (a.pressureProfile.minWidthPx != b.pressureProfile.minWidthPx ||
      a.pressureProfile.maxWidthPx != b.pressureProfile.maxWidthPx ||
      a.pressureProfile.minOpacity != b.pressureProfile.minOpacity ||
      a.pressureProfile.maxOpacity != b.pressureProfile.maxOpacity ||
      a.pressureProfile.enabled != b.pressureProfile.enabled) {
    return false;
  }
  if (a.points.length != b.points.length) return false;
  for (var i = 0; i < a.points.length; i++) {
    if (a.points[i] != b.points[i]) return false;
  }
  return true;
}

String canvasSnapshotDiff(CanvasSnapshot expected, CanvasSnapshot actual) {
  final buffer = StringBuffer('Canvas snapshots differ.\n');
  if (expected.particleStyle != actual.particleStyle) {
    buffer.writeln(
      '  particleStyle: expected ${expected.particleStyle}, got ${actual.particleStyle}',
    );
  }
  if (expected.pressureProfile != actual.pressureProfile) {
    buffer.writeln('  pressureProfile:');
    buffer.writeln('    expected width ${expected.pressureProfile.minWidthPx}'
        '–${expected.pressureProfile.maxWidthPx}');
    buffer.writeln('    actual width ${actual.pressureProfile.minWidthPx}'
        '–${actual.pressureProfile.maxWidthPx}');
  }
  if (expected.points.length != actual.points.length) {
    buffer.writeln(
      '  point count: expected ${expected.points.length}, got ${actual.points.length}',
    );
  }
  final limit = expected.points.length < actual.points.length
      ? expected.points.length
      : actual.points.length;
  for (var i = 0; i < limit; i++) {
    if (expected.points[i] != actual.points[i]) {
      buffer.writeln(
        '  point[$i]: expected ${expected.points[i]}, got ${actual.points[i]}',
      );
      if (i >= 4) {
        buffer.writeln('  (additional point diffs omitted)');
        break;
      }
    }
  }
  return buffer.toString();
}
