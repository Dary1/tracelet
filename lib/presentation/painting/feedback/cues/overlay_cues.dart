import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_layout.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_helpers.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

abstract final class OverlayCues {
  static void paintSettingsTransition(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final fade = VisualCuePaintHelpers.sineFade(progress);
    final inset = size.shortestSide * 0.06 * (1 - progress);

    final paint = Paint()
      ..isAntiAlias = true
      ..color = style.overlay.withValues(alpha: style.settingsFrameAlpha * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.settingsFrameStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.sweepBlur);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
        Radius.circular(style.settingsFrameRadius),
      ),
      paint,
    );
  }

  static void paintAlert(
    Canvas canvas,
    Size size,
    double progress,
    VisualCuePaintStyle style,
  ) {
    final fade = VisualCuePaintHelpers.sineFade(progress);
    final center = Offset(
      size.width * 0.5,
      size.height * VisualCueLayout.alertCenterY,
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..color = style.overlay.withValues(alpha: style.alertAlpha * fade)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.alertBlur);

    canvas.drawCircle(center, size.width * 0.12 * fade, paint);
  }
}
