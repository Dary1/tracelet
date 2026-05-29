import 'package:flutter/material.dart';
import 'package:tracelet/application/trace_canvas_state.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/presentation/painting/trace/trace_paint_style.dart';

class TracePainter extends CustomPainter {
  TracePainter({
    required this.points,
    required this.repaintTick,
    this.fadeDuration = TraceCanvasState.fadeDurationDefault,
    this.pressureProfile = const TracePressureProfile(),
    this.style = TracePaintStyle.standard,
  });

  final List<TracePoint> points;
  final int repaintTick;
  final Duration fadeDuration;
  final TracePressureProfile pressureProfile;
  final TracePaintStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final now = DateTime.now();
    final fadeMs = fadeDuration.inMilliseconds.toDouble();

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1.isBreak || p2.isBreak) continue;

      final pressure = p1.effectivePressure;
      final baseColor = p1.color ?? style.defaultColor;
      final pressureOpacity = pressureProfile.opacityFor(pressure);
      final strokeWidth = pressureProfile.widthFor(pressure);

      final age = now.difference(p1.timestamp).inMilliseconds.toDouble();
      final lifeRatio = 1.0 - (age / fadeMs);
      if (lifeRatio <= 0) continue;

      final alpha = lifeRatio.clamp(0.0, 1.0) * pressureOpacity;
      if (alpha < style.minLifeAlpha) continue;

      final paint = Paint()
        ..isAntiAlias = true
        ..color = baseColor.withValues(alpha: alpha)
        ..strokeWidth = strokeWidth
        ..strokeCap = style.strokeCap
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.blurSigma);

      canvas.drawLine(p1.position, p2.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.repaintTick != repaintTick ||
      oldDelegate.fadeDuration != fadeDuration ||
      oldDelegate.pressureProfile != pressureProfile ||
      oldDelegate.style != style;
}
