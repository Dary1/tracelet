import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_layout.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_helpers.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

abstract final class ButtonActionCues {
  static void paintButtonB(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final origin = VisualCueLayout.buttonB(size);

    VisualCuePaintHelpers.drawRipples(
      canvas: canvas,
      origin: origin,
      size: size,
      progress: progress,
      color: style.buttonB,
      count: 2,
      radiusFactor: 0.14,
      maxAlpha: 0.55,
      style: style,
    );

    VisualCuePaintHelpers.drawSweepArc(
      canvas: canvas,
      size: size,
      origin: origin,
      progress: progress,
      color: style.buttonB,
      startAngle: math.pi * 1.15,
      sweep: -math.pi * 0.5 * progress,
      style: style,
    );
  }

  static void paintModeChange(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style, {
    required int ripples,
    required bool enabled,
  }) {
    final origin = VisualCueLayout.buttonA(size);

    VisualCuePaintHelpers.drawRipples(
      canvas: canvas,
      origin: origin,
      size: size,
      progress: progress,
      color: style.buttonA,
      count: ripples,
      radiusFactor: 0.15,
      maxAlpha: enabled ? 0.55 : 0.35,
      style: style,
    );

    VisualCuePaintHelpers.drawSweepArc(
      canvas: canvas,
      size: size,
      origin: origin,
      progress: progress,
      color: style.buttonA,
      startAngle: math.pi * 0.75,
      sweep: math.pi * 0.5 * progress,
      style: style,
    );
  }
}
