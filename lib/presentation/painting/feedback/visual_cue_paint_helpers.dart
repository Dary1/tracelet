import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

/// Shared drawing helpers for visual cue painters.
abstract final class VisualCuePaintHelpers {
  static void drawRipples({
    required Canvas canvas,
    required Offset origin,
    required Size size,
    required double progress,
    required Color color,
    required int count,
    required double radiusFactor,
    required double maxAlpha,
    required VisualCuePaintStyle style,
  }) {
    for (var i = 0; i < count; i++) {
      final rippleProgress = (progress * count - i).clamp(0.0, 1.0);
      if (rippleProgress <= 0) continue;

      final radius = size.shortestSide * radiusFactor * rippleProgress;
      final alpha = (1 - rippleProgress) * maxAlpha;

      final paint = Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.rippleStrokeWidth
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur);

      canvas.drawCircle(origin, radius, paint);
    }
  }

  static void drawSweepArc({
    required Canvas canvas,
    required Size size,
    required Offset origin,
    required double progress,
    required Color color,
    required double startAngle,
    required double sweep,
    required VisualCuePaintStyle style,
  }) {
    final fade = 1 - progress;
    final paint = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: 0.55 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.sweepStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.sweepBlur);

    canvas.drawArc(
      Rect.fromCircle(
        center: origin,
        radius: size.shortestSide * 0.08 * progress,
      ),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  static double sineFade(double progress) => math.sin(progress * math.pi);
}
