import 'dart:ui';



import 'package:tracelet/application/trace_canvas_state.dart';

import 'package:tracelet/domain/models/trace_playback_profile.dart';

import 'package:tracelet/domain/models/trace_point.dart';

import 'package:tracelet/domain/traces/trace_playback_mapper.dart';



/// Host for rendering a stored trace one point at a time.

abstract class TracePointPlaybackHost {

  Future<void> beginTracePlayback({

    required TracePlaybackProfile playbackProfile,

    required bool clearFirst,

    required Duration fadeDuration,

  });



  Future<void> renderTracePoint(

    TracePoint point, {

    TracePoint? previous,

  });



  Future<void> renderTraceStrokeBreak();



  Future<void> waitForTraceInterval(int delayMs);



  Future<void> endTracePlayback();

}



abstract final class TracePointPlayer {

  static Future<void> playByPoints({

    required TracePointPlaybackHost host,

    required List<TracePoint> storedPoints,

    required TracePlaybackProfile playbackProfile,

    required Size canvasSize,

    bool clearFirst = true,

    Duration fadeDuration = TraceCanvasState.fadeDurationDefault,

  }) async {

    if (storedPoints.isEmpty) return;



    final mapped = TracePlaybackMapper.mapPoints(

      points: storedPoints,

      playback: playbackProfile,

      canvasSize: canvasSize,

    );



    await host.beginTracePlayback(

      playbackProfile: playbackProfile,

      clearFirst: clearFirst,

      fadeDuration: fadeDuration,

    );



    TracePoint? previous;

    for (final point in mapped) {

      if (point.isBreak) {

        await host.renderTraceStrokeBreak();

        previous = null;

        continue;

      }



      if (previous != null && !previous.isBreak) {

        final delayMs =

            point.timestamp.difference(previous.timestamp).inMilliseconds;

        if (delayMs > 0) {

          await host.waitForTraceInterval(delayMs);

        }

      }



      await host.renderTracePoint(point, previous: previous);

      previous = point;

    }



    await host.endTracePlayback();

  }

}


