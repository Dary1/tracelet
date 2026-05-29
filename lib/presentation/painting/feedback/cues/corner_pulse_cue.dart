import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_layout.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_helpers.dart';
import 'package:tracelet/presentation/painting/feedback/visual_cue_paint_style.dart';

abstract final class CornerPulseCue {
  static void paint(
    Canvas canvas,
    Size size,
    double progress,
    Color color,
    bool enabled,
    VisualCuePaintStyle style, {
    bool right = false,
  }) {
    final fade = VisualCuePaintHelpers.sineFade(progress);
    final alpha = fade * (enabled ? 0.7 : 0.28);
    final corner = VisualCueLayout.corner(size, right: right);

    final glow = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glowBlur);

    canvas.drawCircle(corner, size.width * 0.18 * fade, glow);

    final lineY = size.height * VisualCueLayout.pulseLineY;
    final linePaint = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: alpha * 0.85)
      ..strokeWidth = style.lineStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.lineBlur);

    final startX = right ? size.width * 0.55 : size.width * 0.05;
    final endX = right ? size.width * 0.95 : size.width * 0.45;
    final mid = startX + (endX - startX) * fade;
    canvas.drawLine(Offset(startX, lineY), Offset(mid, lineY), linePaint);
  }
}
