import 'dart:math' as math;
import 'dart:ui';

import 'package:tracelet/domain/models/trace_coordinate_space.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_point.dart';

/// Maps stored trace coordinates onto the local canvas for playback.
abstract final class TracePlaybackMapper {
  static double uniformScale({
    required Size canvasSize,
    required double captureWidth,
    required double captureHeight,
  }) {
    if (captureWidth <= 0 || captureHeight <= 0) return 1.0;
    return math.min(
      canvasSize.width / captureWidth,
      canvasSize.height / captureHeight,
    );
  }

  static Offset contentOffset({
    required Size canvasSize,
    required double captureWidth,
    required double captureHeight,
    required double scale,
  }) {
    return Offset(
      (canvasSize.width - captureWidth * scale) / 2,
      (canvasSize.height - captureHeight * scale) / 2,
    );
  }

  static Offset toCanvas({
    required Offset stored,
    required TracePlaybackProfile playback,
    required Size canvasSize,
  }) {
    final captureW = playback.captureWidth;
    final captureH = playback.captureHeight;
    if (captureW <= 0 || captureH <= 0) return stored;

    if (playback.coordinateSpace == TraceCoordinateSpace.absolute) {
      final scale = uniformScale(
        canvasSize: canvasSize,
        captureWidth: captureW,
        captureHeight: captureH,
      );
      final offset = contentOffset(
        canvasSize: canvasSize,
        captureWidth: captureW,
        captureHeight: captureH,
        scale: scale,
      );
      return Offset(
        stored.dx * scale + offset.dx,
        stored.dy * scale + offset.dy,
      );
    }

    final scale = uniformScale(
      canvasSize: canvasSize,
      captureWidth: captureW,
      captureHeight: captureH,
    );
    final offset = contentOffset(
      canvasSize: canvasSize,
      captureWidth: captureW,
      captureHeight: captureH,
      scale: scale,
    );
    return Offset(
      offset.dx + stored.dx * captureW * scale,
      offset.dy + stored.dy * captureH * scale,
    );
  }

  static List<TracePoint> mapPoints({
    required List<TracePoint> points,
    required TracePlaybackProfile playback,
    required Size canvasSize,
  }) {
    return [
      for (final point in points)
        if (point.isBreak)
          point
        else
          point.copyWith(
            position: toCanvas(
              stored: point.position,
              playback: playback,
              canvasSize: canvasSize,
            ),
          ),
    ];
  }
}
