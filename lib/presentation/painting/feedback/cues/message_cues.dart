import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/cues/corner_pulse_cue.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_layout.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_helpers.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

abstract final class MessageCues {
  static void paintMessageStart(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final fade = 1 - progress;
    final origin = VisualCueLayout.buttonB(size);

    final paint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonB.withValues(alpha: 0.75 * fade)
      ..strokeWidth = style.rippleStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.sweepBlur);

    final length = size.width * 0.35 * progress;
    canvas.drawLine(
      origin,
      Offset(origin.dx - length, origin.dy - length * 0.35),
      paint,
    );
  }

  static void paintFriendConnected(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final left = Offset(
      size.width * VisualCueLayout.friendLeftX,
      size.height * VisualCueLayout.friendY,
    );
    final right = Offset(
      size.width * VisualCueLayout.friendRightX,
      size.height * VisualCueLayout.friendY,
    );
    final center = Offset.lerp(left, right, progress)!;
    final fade = VisualCuePaintHelpers.sineFade(progress);

    final dotPaint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonB.withValues(alpha: 0.85 * fade)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.sweepBlur);

    canvas.drawCircle(left, style.dotRadius, dotPaint);
    canvas.drawCircle(right, style.dotRadius, dotPaint);

    final linePaint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonB.withValues(alpha: 0.65 * fade)
      ..strokeWidth = style.lineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.lineBlur);

    canvas.drawLine(left, center, linePaint);
  }

  static void paintSenderRemoved(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final fade = VisualCuePaintHelpers.sineFade(progress);
    final center = Offset(
      size.width * 0.5,
      size.height * VisualCueLayout.senderRemovedCenterY,
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..color = style.overlay.withValues(alpha: 0.38 * fade)
      ..strokeWidth = style.lineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.lineBlur);

    final span = size.width * 0.08;
    canvas.drawLine(
      Offset(center.dx - span, center.dy - span),
      Offset(center.dx + span, center.dy + span),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + span, center.dy - span),
      Offset(center.dx - span, center.dy + span),
      paint,
    );

    CornerPulseCue.paint(canvas, size, progress, style.buttonA, false, style);
    CornerPulseCue.paint(
      canvas,
      size,
      progress,
      style.buttonB,
      false,
      style,
      right: true,
    );
  }

  static void paintDestinationSwitch(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    VisualCuePaintHelpers.drawSweepArc(
      canvas: canvas,
      size: size,
      origin: VisualCueLayout.buttonB(size),
      progress: progress,
      color: style.buttonB,
      startAngle: math.pi,
      sweep: -math.pi * 0.45 * progress,
      style: style,
    );
  }
}
