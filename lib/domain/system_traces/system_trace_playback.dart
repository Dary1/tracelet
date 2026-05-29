import 'dart:ui';

import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/models/trace_point.dart';

/// Converts authored system traces into normalized points for [TracePointPlayer].
abstract final class SystemTracePlayback {
  static const stepDuration = TraceCanvasState.playbackStep;

  static List<TracePoint> pointsFor(SystemTraceDocument document) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final points = <TracePoint>[];
    var elapsedMs = 0;

    for (final stroke in document.strokes) {
      for (var i = 0; i < stroke.points.length; i++) {
        final sample = stroke.points[i];
        if (i == 0) {
          if (sample.t > 0) {
            elapsedMs = sample.t;
          }
        } else if (sample.t > 0 && sample.t > elapsedMs) {
          elapsedMs = sample.t;
        } else {
          elapsedMs += stepDuration.inMilliseconds;
        }

        final strokeColor =
            stroke.color?.withValues(alpha: stroke.opacity.clamp(0.0, 1.0));

        points.add(
          TracePoint(
            position: sample.toOffset(),
            timestamp: epoch.add(Duration(milliseconds: elapsedMs)),
            color: strokeColor,
            pressure: 1.0,
          ),
        );
      }

      points.add(
        TracePoint(
          position: TracePoint.strokeBreak,
          timestamp: epoch.add(Duration(milliseconds: elapsedMs)),
          isStrokeBreak: true,
        ),
      );
    }

    return points;
  }
}
