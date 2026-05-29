import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/system_trace.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_paths.dart';
import 'package:tracelet/domain/system_traces/system_trace_playback.dart';
import 'package:tracelet/domain/system_traces/system_trace_theme_id.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('system trace assets convert to timed points for TracePointPlayer', () async {
    final raw = await rootBundle.loadString(
      SystemTracePaths.assetPath(
        SystemTraceThemeId.defaultTheme,
        SystemTraceId.messagePlayback,
      ),
    );
    final document = SystemTraceDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    const canvasSize = Size(390, 844);
    final userProfile = TraceProfilePresets.littlePrettify;

    final points = SystemTracePlayback.pointsFor(document);
    expect(points.where((point) => !point.isBreak).length, greaterThan(5));
    expect(points.any((point) => point.isBreak), isTrue);

    final host = _RecordingPlaybackHost();
    await TracePointPlayer.playByPoints(
      host: host,
      storedPoints: points,
      playbackProfile: TracePlaybackProfile.forSystemTrace(
        canvasSize: canvasSize,
        preset: userProfile.preset,
        particles: userProfile.particles,
        pressure: userProfile.pressure,
      ),
      canvasSize: canvasSize,
      fadeDuration: TraceCanvasState.fadeDurationDefault,
    );

    expect(host.events.first, 'begin');
    expect(host.events.last, 'end');
    expect(host.rendered, isNotEmpty);
    expect(host.rendered.first.position.dx, closeTo(0.12 * canvasSize.width, 1));
  });
}
