import 'package:flutter/material.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_layout.dart';
import 'package:tracelet/presentation/painting/hardware/hardware_button_style.dart';

class HardwareButtonRipplePainter extends CustomPainter {
  HardwareButtonRipplePainter({
    required this.color,
    required this.progress,
    required this.fromRight,
    this.style = HardwareButtonStyle.standard,
  });

  final Color color;
  final double progress;
  final bool fromRight;
  final HardwareButtonStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(
      fromRight ? size.width : 0,
      size.height,
    );
    final radius =
        size.shortestSide * HardwareButtonLayout.rippleRadiusFraction * progress;
    final alpha = (1 - progress) * style.rippleMaxAlpha;
    final innerAlpha = alpha * 0.55;

    final paint = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.rippleStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur);

    canvas.drawCircle(origin, radius, paint);

    if (progress < 0.65) {
      final innerPaint = Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: innerAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.rippleStrokeWidth * 0.6
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.rippleBlur * 0.6);
      canvas.drawCircle(origin, radius * 0.72, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HardwareButtonRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
