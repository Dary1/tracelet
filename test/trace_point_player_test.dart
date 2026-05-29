import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/traces/trace_point_player.dart';

class _RecordingPlaybackHost implements TracePointPlaybackHost {
  final List<String> events = [];
  final List<TracePoint> rendered = [];

  @override
  Future<void> beginTracePlayback({
    required TracePlaybackProfile playbackProfile,
    required bool clearFirst,
    required Duration fadeDuration,
  }) async {
    events.add('begin');
  }

  @override
  Future<void> endTracePlayback() async {
    events.add('end');
  }

  @override
  Future<void> renderTracePoint(
    TracePoint point, {
    TracePoint? previous,
  }) async {
    rendered.add(point);
    events.add('point');
  }

  @override
  Future<void> renderTraceStrokeBreak() async {
    events.add('break');
  }

  @override
  Future<void> waitForTraceInterval(int delayMs) async {
    events.add('wait:$delayMs');
  }
}

void main() {
  test('TracePointPlayer replays points in order with timing gaps', () async {
    final host = _RecordingPlaybackHost();
    const canvasSize = Size(400, 800);
    final playbackProfile =
        TraceProfilePresets.pureFinger.toPlaybackProfile(canvasSize);
    final points = [
      TracePoint(
        position: const Offset(0.025, 0.0125),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      TracePoint(
        position: const Offset(0.05, 0.025),
        timestamp: DateTime.fromMillisecondsSinceEpoch(50),
      ),
      TracePoint(
        position: TracePoint.strokeBreak,
        timestamp: DateTime.fromMillisecondsSinceEpoch(60),
        isStrokeBreak: true,
      ),
    ];

    await TracePointPlayer.playByPoints(
      host: host,
      storedPoints: points,
      playbackProfile: playbackProfile,
      canvasSize: canvasSize,
    );

    expect(host.events, ['begin', 'point', 'wait:50', 'point', 'break', 'end']);
    expect(host.rendered, hasLength(2));
    expect(host.rendered.first.position.dx, closeTo(10, 0.5));
  });
}
