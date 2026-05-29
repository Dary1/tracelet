import 'dart:math' as math;
import 'dart:ui';

import 'package:tracelet/domain/models/trace_process_profile.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';

/// Applies [TraceProfile] transforms to raw canvas captures at send time.
abstract final class TraceProcessor {
  static List<TracePoint> process({
    required List<TracePoint> raw,
    required TraceProfile profile,
    required Size captureSize,
  }) {
    if (raw.isEmpty) return const [];

    final strokes = _splitStrokes(raw);
    final processedStrokes = <List<TracePoint>>[];

    for (final stroke in strokes) {
      var points = stroke;
      if (points.length < 2) {
        processedStrokes.add(points);
        continue;
      }

      points = _filterMinDistance(points, profile.minPointDistancePx);
      if (points.length < 2) continue;

      if (profile.smoothingStrength > 0) {
        points = _smooth(points, profile.smoothingStrength, profile.cornerPreservation);
      }

      if (profile.simplifyTolerancePx > 0) {
        final tolerance = profile.simplifyTolerancePx * (1.1 - profile.cornerPreservation * 0.5);
        points = _simplifyRdp(points, tolerance.clamp(0, 12));
      }

      if (profile.resampleStepPx > 0) {
        points = _resample(points, profile.resampleStepPx);
      }

      if (points.length >= 2) {
        processedStrokes.add(points);
      }
    }

    var flat = _joinStrokes(processedStrokes);
    flat = _applySpatial(flat, profile, captureSize);
    flat = _applyTiming(flat, profile);
    if (profile.pressure.enabled && profile.pressure.smoothingStrength > 0) {
      flat = _smoothPressure(flat, profile.pressure.smoothingStrength);
    }
    return flat;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static List<TracePoint> _smoothPressure(List<TracePoint> points, double strength) {
    if (points.length < 3 || strength <= 0) return points;
    final window = (1 + strength * 6).round().clamp(1, 7);
    final out = <TracePoint>[];
    for (var i = 0; i < points.length; i++) {
      if (points[i].isBreak) {
        out.add(points[i]);
        continue;
      }
      var sum = 0.0;
      var count = 0;
      for (var j = i - window; j <= i + window; j++) {
        if (j < 0 || j >= points.length || points[j].isBreak) continue;
        sum += points[j].effectivePressure;
        count++;
      }
      out.add(
        points[i].copyWith(pressure: count > 0 ? sum / count : points[i].effectivePressure),
      );
    }
    return out;
  }

  static List<List<TracePoint>> _splitStrokes(List<TracePoint> points) {
    final strokes = <List<TracePoint>>[];
    var current = <TracePoint>[];
    for (final point in points) {
      if (point.isBreak) {
        if (current.isNotEmpty) strokes.add(current);
        current = [];
        continue;
      }
      current.add(point);
    }
    if (current.isNotEmpty) strokes.add(current);
    return strokes;
  }

  static List<TracePoint> _joinStrokes(List<List<TracePoint>> strokes) {
    final out = <TracePoint>[];
    for (var i = 0; i < strokes.length; i++) {
      out.addAll(strokes[i]);
      if (i < strokes.length - 1) {
        final last = strokes[i].last;
        out.add(
          TracePoint(
            position: TracePoint.strokeBreak,
            timestamp: last.timestamp,
            isStrokeBreak: true,
          ),
        );
      }
    }
    return out;
  }

  static List<TracePoint> _filterMinDistance(List<TracePoint> points, double minDist) {
    if (minDist <= 0 || points.length < 2) return points;
    final out = <TracePoint>[points.first];
    for (var i = 1; i < points.length; i++) {
      if ((points[i].position - out.last.position).distance >= minDist) {
        out.add(points[i]);
      }
    }
    return out.length >= 2 ? out : points;
  }

  static List<TracePoint> _smooth(
    List<TracePoint> points,
    double strength,
    double cornerPreservation,
  ) {
    final window = (1 + strength * 8).round().clamp(1, 9);
    if (window <= 1) return points;

    final out = <TracePoint>[];
    for (var i = 0; i < points.length; i++) {
      var sumX = 0.0;
      var sumY = 0.0;
      var sumP = 0.0;
      var count = 0;
      var pCount = 0;
      for (var j = i - window; j <= i + window; j++) {
        if (j < 0 || j >= points.length) continue;
        final weight = j == i ? 1 + cornerPreservation : 1.0;
        sumX += points[j].position.dx * weight;
        sumY += points[j].position.dy * weight;
        count += weight.round();
        sumP += points[j].effectivePressure * weight;
        pCount += weight.round();
      }
      out.add(
        points[i].copyWith(
          position: Offset(sumX / count, sumY / count),
          pressure: pCount > 0 ? sumP / pCount : points[i].effectivePressure,
        ),
      );
    }
    return out;
  }

  static List<TracePoint> _simplifyRdp(List<TracePoint> points, double epsilon) {
    if (points.length < 3 || epsilon <= 0) return points;
    final keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;
    _rdp(points, 0, points.length - 1, epsilon, keep);
    return [for (var i = 0; i < points.length; i++) if (keep[i]) points[i]];
  }

  static void _rdp(
    List<TracePoint> points,
    int start,
    int end,
    double epsilon,
    List<bool> keep,
  ) {
    if (end <= start + 1) return;
    var maxDist = 0.0;
    var index = start;
    final a = points[start].position;
    final b = points[end].position;
    for (var i = start + 1; i < end; i++) {
      final d = _perpendicularDistance(points[i].position, a, b);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }
    if (maxDist > epsilon) {
      keep[index] = true;
      _rdp(points, start, index, epsilon, keep);
      _rdp(points, index, end, epsilon, keep);
    }
  }

  static double _perpendicularDistance(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    final proj = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - proj).distance;
  }

  static List<TracePoint> _resample(List<TracePoint> points, double step) {
    if (step <= 0 || points.length < 2) return points;
    final out = <TracePoint>[points.first];
    var carry = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = out.last;
      final b = points[i];
      final segLen = (b.position - a.position).distance;
      if (segLen <= 0) continue;
      var dist = carry;
      while (dist + step <= segLen) {
        dist += step;
        final t = dist / segLen;
        final pos = Offset.lerp(a.position, b.position, t)!;
        final timeMs = a.timestamp.millisecondsSinceEpoch +
            ((b.timestamp.millisecondsSinceEpoch - a.timestamp.millisecondsSinceEpoch) * t).round();
        out.add(
          TracePoint(
            position: pos,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
            color: b.color ?? a.color,
            pressure: _lerp(a.effectivePressure, b.effectivePressure, t),
          ),
        );
      }
      carry = (carry + segLen) % step;
      out.add(b);
    }
    return out;
  }

  static List<TracePoint> _applySpatial(
    List<TracePoint> points,
    TraceProfile profile,
    Size captureSize,
  ) {
    if (captureSize.width <= 0 || captureSize.height <= 0) return points;
    return [
      for (final point in points)
        if (point.isBreak)
          point
        else
          point.copyWith(
            position: Offset(
              point.position.dx / captureSize.width,
              point.position.dy / captureSize.height,
            ),
          ),
    ];
  }

  static List<TracePoint> _applyTiming(List<TracePoint> points, TraceProfile profile) {
    if (points.isEmpty || profile.timingMode == TraceTimingMode.wallClock) {
      return points;
    }

    final drawable = points.where((p) => !p.isBreak).toList();
    if (drawable.length < 2) return points;

    final startMs = drawable.first.timestamp.millisecondsSinceEpoch;
    final endMs = drawable.last.timestamp.millisecondsSinceEpoch;
    final span = math.max(endMs - startMs, 1);

    int mapTime(int originalMs) {
      final rel = originalMs - startMs;
      return switch (profile.timingMode) {
        TraceTimingMode.compressed => () {
            final scaled = (rel / profile.speedMultiplier).round();
            final stepped = profile.minPointIntervalMs > 0
                ? (scaled / profile.minPointIntervalMs).round() * profile.minPointIntervalMs
                : scaled;
            return startMs + stepped;
          }(),
        TraceTimingMode.fixedDuration => () {
            final ratio = rel / span;
            return startMs + (ratio * profile.targetDurationMs).round();
          }(),
        TraceTimingMode.wallClock => originalMs,
      };
    }

    if (!profile.preserveStrokePauses && profile.timingMode == TraceTimingMode.fixedDuration) {
      var t = 0;
      final step = (profile.targetDurationMs / math.max(drawable.length - 1, 1)).round();
      return [
        for (final point in points)
          if (point.isBreak)
            point
          else
            point.copyWith(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                startMs + (t++ * step),
              ),
            ),
      ];
    }

    return [
      for (final point in points)
        if (point.isBreak)
          point
        else
          point.copyWith(
            timestamp: DateTime.fromMillisecondsSinceEpoch(mapTime(point.timestamp.millisecondsSinceEpoch)),
          ),
    ];
  }
}
