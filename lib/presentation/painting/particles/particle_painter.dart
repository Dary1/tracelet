import 'package:flutter/material.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/traces/particle_emitter.dart';
import 'package:tracelet/presentation/painting/particles/particle_paint_style.dart';

class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.particles,
    required this.repaintTick,
    this.style = ParticleEffectStyle.off,
    this.paintStyle = ParticlePaintStyle.standard,
  });

  final List<TraceParticle> particles;
  final int repaintTick;
  final ParticleEffectStyle style;
  final ParticlePaintStyle paintStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || style == ParticleEffectStyle.off) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final particle in particles) {
      final opacity = particle.opacityAt(now);
      if (opacity <= 0) continue;

      final clampedOpacity = opacity.clamp(0.0, 1.0);

      switch (style) {
        case ParticleEffectStyle.glow:
          _paintGlow(canvas, particle, clampedOpacity);
        case ParticleEffectStyle.sparkle:
          _paintSparkle(canvas, particle, clampedOpacity);
        case ParticleEffectStyle.drift:
          _paintDrift(canvas, particle, clampedOpacity);
        case ParticleEffectStyle.ember:
          _paintEmber(canvas, particle, clampedOpacity);
        case ParticleEffectStyle.off:
          break;
      }
    }
  }

  void _paintGlow(Canvas canvas, TraceParticle particle, double opacity) {
    final blur = particle.sizePx * paintStyle.glowBlurMultiplier;

    final haloPaint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity * paintStyle.glowHaloAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawCircle(
      particle.position,
      particle.sizePx * paintStyle.glowHaloScale,
      haloPaint,
    );

    final corePaint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.45);

    canvas.drawCircle(
      particle.position,
      particle.sizePx * paintStyle.glowCoreScale,
      corePaint,
    );
  }

  void _paintSparkle(Canvas canvas, TraceParticle particle, double opacity) {
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity);

    canvas.drawCircle(particle.position, particle.sizePx, fillPaint);

    final arm = particle.sizePx * paintStyle.sparkleArmMultiplier;
    final linePaint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity * 0.85)
      ..strokeWidth = paintStyle.sparkleStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      particle.position - Offset(arm, 0),
      particle.position + Offset(arm, 0),
      linePaint,
    );
    canvas.drawLine(
      particle.position - Offset(0, arm),
      particle.position + Offset(0, arm),
      linePaint,
    );
  }

  void _paintDrift(Canvas canvas, TraceParticle particle, double opacity) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity);

    canvas.drawCircle(
      particle.position,
      particle.sizePx * paintStyle.driftCoreScale,
      paint,
    );
  }

  void _paintEmber(Canvas canvas, TraceParticle particle, double opacity) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = particle.color.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.sizePx * 0.35);

    canvas.drawCircle(
      particle.position,
      particle.sizePx * paintStyle.emberCoreScale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.repaintTick != repaintTick ||
        oldDelegate.particles.length != particles.length ||
        oldDelegate.style != style ||
        oldDelegate.paintStyle != paintStyle;
  }
}
