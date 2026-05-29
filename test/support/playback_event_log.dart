import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/traces/playback_event_log.dart';
import 'package:tracelet/domain/traces/trace_point_player.dart';

export 'package:tracelet/domain/traces/playback_event_log.dart';

/// Records [TracePointPlayer] realtime replay steps.
class RecordingPlaybackHost implements TracePointPlaybackHost {
  RecordingPlaybackHost(this.clockMs);

  final int Function() clockMs;
  final List<PlaybackEvent> events = [];
  var _pointIndex = 0;

  PlaybackEventLog get log => PlaybackEventLog(List.unmodifiable(events));

  @override
  Future<void> beginTracePlayback({
    required TracePlaybackProfile playbackProfile,
    required bool clearFirst,
    required Duration fadeDuration,
  }) async {
    events.add(PlaybackBegin(clockMs()));
  }

  @override
  Future<void> endTracePlayback() async {
    events.add(PlaybackEnd(clockMs()));
  }

  @override
  Future<void> renderTracePoint(
    TracePoint point, {
    TracePoint? previous,
  }) async {
    events.add(
      PlaybackPoint(
        clockMs(),
        x: point.position.dx,
        y: point.position.dy,
        pressure: point.effectivePressure,
        pointIndex: _pointIndex++,
      ),
    );
  }

  @override
  Future<void> renderTraceStrokeBreak() async {
    events.add(PlaybackBreak(clockMs()));
  }

  @override
  Future<void> waitForTraceInterval(int delayMs) async {
    events.add(PlaybackWait(clockMs(), delayMs));
  }
}

/// Canvas state sampled during an in-flight [playTrace] (growth over time).
class PlaybackProcessSnapshot {
  const PlaybackProcessSnapshot({
    required this.elapsedMs,
    required this.drawablePointCount,
    required this.isPlaying,
    this.lastX,
    this.lastY,
    this.lastPressure,
  });

  final int elapsedMs;
  final int drawablePointCount;
  final bool isPlaying;
  final double? lastX;
  final double? lastY;
  final double? lastPressure;

  factory PlaybackProcessSnapshot.fromState(TraceCanvasState state, int elapsedMs) {
    TracePoint? last;
    for (var i = state.points.length - 1; i >= 0; i--) {
      if (!state.points[i].isBreak) {
        last = state.points[i];
        break;
      }
    }
    return PlaybackProcessSnapshot(
      elapsedMs: elapsedMs,
      drawablePointCount: state.points.where((point) => !point.isBreak).length,
      isPlaying: state.isPlaying,
      lastX: last?.position.dx,
      lastY: last?.position.dy,
      lastPressure: last?.effectivePressure,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackProcessSnapshot &&
        elapsedMs == other.elapsedMs &&
        drawablePointCount == other.drawablePointCount &&
        isPlaying == other.isPlaying &&
        _optNear(lastX, other.lastX) &&
        _optNear(lastY, other.lastY) &&
        _optNear(lastPressure, other.lastPressure);
  }

  static bool _optNear(double? a, double? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 0.05;
  }
}

bool playbackProcessSnapshotsMatch(
  List<PlaybackProcessSnapshot> a,
  List<PlaybackProcessSnapshot> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String playbackProcessDiff(
  List<PlaybackProcessSnapshot> expected,
  List<PlaybackProcessSnapshot> actual,
) {
  final buffer = StringBuffer('Playback process differs.\n');
  if (expected.length != actual.length) {
    buffer.writeln(
      '  snapshot count: expected ${expected.length}, got ${actual.length}',
    );
  }
  final limit = expected.length < actual.length ? expected.length : actual.length;
  for (var i = 0; i < limit; i++) {
    if (expected[i] != actual[i]) {
      buffer.writeln('  [$i] expected ${expected[i]}, got ${actual[i]}');
      if (i >= 6) {
        buffer.writeln('  (additional diffs omitted)');
        break;
      }
    }
  }
  return buffer.toString();
}

String playbackEventLogDiff(PlaybackEventLog expected, PlaybackEventLog actual) {
  if (expected.sameProcessAs(actual)) return 'Playback event logs match.';
  final buffer = StringBuffer('Playback event logs differ.\n');
  final a = expected.events;
  final b = actual.events;
  if (a.length != b.length) {
    buffer.writeln('  event count: expected ${a.length}, got ${b.length}');
  }
  final limit = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < limit; i++) {
    if (!_eventsMatchShape(a[i], b[i])) {
      buffer.writeln('  [$i] expected ${a[i]}, got ${b[i]}');
      if (i >= 6) {
        buffer.writeln('  (additional diffs omitted)');
        break;
      }
    }
  }
  return buffer.toString();
}

bool _eventsMatchShape(PlaybackEvent a, PlaybackEvent b) {
  return switch (a) {
    PlaybackBegin() => b is PlaybackBegin,
    PlaybackEnd() => b is PlaybackEnd,
    PlaybackBreak() => b is PlaybackBreak,
    PlaybackWait() => b is PlaybackWait && a.delayMs == b.delayMs,
    PlaybackPoint() =>
      b is PlaybackPoint &&
          (a.x - b.x).abs() < 0.05 &&
          (a.y - b.y).abs() < 0.05 &&
          (a.pressure - b.pressure).abs() < 0.05 &&
          a.pointIndex == b.pointIndex,
  };
}
