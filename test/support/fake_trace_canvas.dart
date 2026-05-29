import 'dart:ui';

import 'package:tracelet/domain/models/trace_point.dart';

/// Records canvas points the same way production [BottleDrawNotifier] does.
class FakeTraceCanvas {
  final List<TracePoint> points = [];

  void addPoint(Offset position) {
    points.add(TracePoint(position: position, timestamp: DateTime.now()));
  }

  void endStroke() {
    points.add(
      TracePoint(
        position: TracePoint.strokeBreak,
        timestamp: DateTime.now(),
        isStrokeBreak: true,
      ),
    );
  }

  void clear() => points.clear();

  int get visiblePointCount => points.where((point) => !point.isBreak).length;
}
