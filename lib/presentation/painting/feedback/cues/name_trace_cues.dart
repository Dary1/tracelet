import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_layout.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_helpers.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

abstract final class NameTraceCues {
  static void paintRegistration(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final left = VisualCueLayout.buttonA(size);
    final right = VisualCueLayout.buttonB(size);
    final meet = Offset.lerp(left, right, progress)!;
    final fade = VisualCuePaintHelpers.sineFade(progress);

    final leftPaint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonA.withValues(alpha: 0.58 * fade)
      ..strokeWidth = style.rippleStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur);

    final rightPaint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonB.withValues(alpha: 0.58 * fade)
      ..strokeWidth = style.rippleStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur);

    canvas.drawLine(left, meet, leftPaint);
    canvas.drawLine(right, meet, rightPaint);

    canvas.drawCircle(
      meet,
      style.meetPointRadius * fade,
      Paint()
        ..isAntiAlias = true
        ..color = style.overlay.withValues(alpha: 0.48 * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur),
    );
  }

  static void paintSaved(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final center = Offset(
      size.width * VisualCueLayout.buttonAX,
      size.height * VisualCueLayout.nameTraceSavedY,
    );
    final fade = VisualCuePaintHelpers.sineFade(progress);
    final radius = size.width * 0.1 * progress;

    final paint = Paint()
      ..isAntiAlias = true
      ..color = style.buttonA.withValues(alpha: 0.65 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.sweepBlur);

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius * 0.55,
      paint..color = paint.color.withValues(alpha: 0.38 * fade),
    );
  }
}
