import 'dart:math' as math;
import 'dart:ui';

import 'package:tracelet/domain/models/trace_point.dart';

/// Geometry helpers for cross-device spatial intent tests.
abstract final class SpatialIntentGeometry {
  static List<TracePoint> circleTracePoints({
    required Offset centre,
    required double radius,
    int count = 32,
    DateTime? epoch,
  }) {
    final start = epoch ?? DateTime.fromMillisecondsSinceEpoch(0);
    return [
      for (var i = 0; i < count; i++)
        TracePoint(
          position: centre +
              Offset(
                math.cos(2 * math.pi * i / count) * radius,
                math.sin(2 * math.pi * i / count) * radius,
              ),
          timestamp: start.add(Duration(milliseconds: i * 12)),
          pressure: 1.0,
        ),
    ];
  }

  static List<TracePoint> squareTracePoints({
    required Rect bounds,
    DateTime? epoch,
  }) {
    final start = epoch ?? DateTime.fromMillisecondsSinceEpoch(0);
    final corners = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft,
      bounds.topLeft,
    ];
    return [
      for (var i = 0; i < corners.length; i++)
        TracePoint(
          position: corners[i],
          timestamp: start.add(Duration(milliseconds: i * 12)),
          pressure: 1.0,
        ),
    ];
  }

  static List<TracePoint> drawablePoints(Iterable<TracePoint> points) {
    return points.where((point) => !point.isBreak).toList(growable: false);
  }

  static Offset centroid(Iterable<TracePoint> points) {
    final drawable = drawablePoints(points);
    if (drawable.isEmpty) return Offset.zero;

    var sumX = 0.0;
    var sumY = 0.0;
    for (final point in drawable) {
      sumX += point.position.dx;
      sumY += point.position.dy;
    }
    return Offset(sumX / drawable.length, sumY / drawable.length);
  }

  static Rect boundingBox(Iterable<TracePoint> points) {
    final drawable = drawablePoints(points);
    assert(drawable.isNotEmpty, 'need at least one drawable point');

    var minX = drawable.first.position.dx;
    var maxX = minX;
    var minY = drawable.first.position.dy;
    var maxY = minY;

    for (final point in drawable.skip(1)) {
      minX = math.min(minX, point.position.dx);
      maxX = math.max(maxX, point.position.dx);
      minY = math.min(minY, point.position.dy);
      maxY = math.max(maxY, point.position.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static double bboxAspectRatio(Iterable<TracePoint> points) {
    final box = boundingBox(points);
    return box.width / box.height;
  }

  static Offset relativeCentre(Iterable<TracePoint> points, Size canvas) {
    final centre = centroid(points);
    return Offset(centre.dx / canvas.width, centre.dy / canvas.height);
  }

  static List<double> pairwiseDistanceScaleFactors({
    required List<Offset> sender,
    required List<Offset> receiver,
    double minSenderDistance = 1,
  }) {
    assert(sender.length == receiver.length);
    final scales = <double>[];

    for (var i = 0; i < sender.length - 1; i++) {
      for (var j = i + 1; j < sender.length; j++) {
        final senderDistance = (sender[i] - sender[j]).distance;
        if (senderDistance < minSenderDistance) continue;
        final receiverDistance = (receiver[i] - receiver[j]).distance;
        scales.add(receiverDistance / senderDistance);
      }
    }

    return scales;
  }

  static List<TracePoint> normalizePoints(
    Iterable<TracePoint> points,
    Size canvas,
  ) {
    return [
      for (final point in points)
        if (point.isBreak)
          point
        else
          point.copyWith(
            position: Offset(
              point.position.dx / canvas.width,
              point.position.dy / canvas.height,
            ),
          ),
    ];
  }

  static List<TracePoint> circleTracePointsNormalized({
    required Offset centre,
    required Size canvas,
    required double radius,
    int count = 32,
  }) {
    return normalizePoints(
      circleTracePoints(centre: centre, radius: radius, count: count),
      canvas,
    );
  }

  static List<TracePoint> squareTracePointsNormalized({
    required Rect bounds,
    required Size canvas,
  }) {
    return normalizePoints(
      squareTracePoints(bounds: bounds),
      canvas,
    );
  }

  static double angleAt(Offset a, Offset b, Offset c) {
    final ba = a - b;
    final bc = c - b;
    return math.atan2(
      ba.dx * bc.dy - ba.dy * bc.dx,
      ba.dx * bc.dx + ba.dy * bc.dy,
    ).abs();
  }
}
