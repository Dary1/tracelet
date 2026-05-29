import 'package:flutter/material.dart';
import 'package:tracelet/domain/models/trace_point.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/traces/particle_emitter.dart';
import 'package:tracelet/presentation/painting/particles/particle_painter.dart';
import 'package:tracelet/presentation/painting/trace/trace_painter.dart';

/// Rendering layer — trace strokes and particle effects only.
class TraceCanvasLayers extends StatelessWidget {
  const TraceCanvasLayers({
    super.key,
    required this.points,
    required this.repaintTick,
    required this.fadeDuration,
    required this.pressureProfile,
    required this.particles,
    required this.particleStyle,
  });

  final List<TracePoint> points;
  final int repaintTick;
  final Duration fadeDuration;
  final TracePressureProfile pressureProfile;
  final List<TraceParticle> particles;
  final ParticleEffectStyle particleStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: TracePainter(
            points: points,
            repaintTick: repaintTick,
            fadeDuration: fadeDuration,
            pressureProfile: pressureProfile,
          ),
        ),
        CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            repaintTick: repaintTick,
            style: particleStyle,
          ),
        ),
      ],
    );
  }
}
