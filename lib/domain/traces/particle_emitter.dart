import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';

/// Runtime particle instance (not stored in payload).
class TraceParticle {
  TraceParticle({
    required this.position,
    required this.velocity,
    required this.bornAtMs,
    required this.lifetimeMs,
    required this.sizePx,
    required this.color,
    required this.startOpacity,
    required this.endOpacity,
  });

  Offset position;
  Offset velocity;
  final int bornAtMs;
  final int lifetimeMs;
  final double sizePx;
  final Color color;
  final double startOpacity;
  final double endOpacity;

  double ageRatio(int nowMs) =>
      ((nowMs - bornAtMs) / lifetimeMs).clamp(0.0, 1.0);

  double opacityAt(int nowMs) {
    final t = ageRatio(nowMs);
    return startOpacity + (endOpacity - startOpacity) * t;
  }

  bool isAlive(int nowMs) => nowMs - bornAtMs < lifetimeMs;
}

/// Spawns and simulates particles from header params + stroke head at runtime.
class ParticleEmitter {
  ParticleEmitter({this.profile = const ParticleEffectProfile()});

  ParticleEffectProfile profile;
  final List<TraceParticle> particles = [];
  int _lastSpawnMs = 0;
  math.Random? _random;

  void configure(ParticleEffectProfile profile) {
    this.profile = profile;
    _random = profile.seed != null ? math.Random(profile.seed) : math.Random();
  }

  void clear() {
    particles.clear();
    _lastSpawnMs = 0;
  }

  math.Random get _rng => _random ??= math.Random();

  void onStrokeHead({
    required Offset position,
    required Offset? tangent,
    required Color? strokeColor,
    required int nowMs,
    double densityScale = 1,
  }) {
    if (!profile.enabled || profile.particlesPerBurst <= 0) return;
    if (nowMs - _lastSpawnMs < profile.spawnIntervalMs) return;
    if (_rng.nextDouble() > profile.density * densityScale) return;

    _lastSpawnMs = nowMs;
    final baseAngle = tangent != null && tangent.distance > 0.001
        ? math.atan2(tangent.dy, tangent.dx)
        : 0.0;
    final spreadRad = profile.spreadAngleDeg * math.pi / 180;

    for (var i = 0; i < profile.particlesPerBurst; i++) {
      final angle = baseAngle + (_rng.nextDouble() - 0.5) * spreadRad;
      final speed = profile.speedMinPx +
          _rng.nextDouble() * (profile.speedMaxPx - profile.speedMinPx);
      final size = profile.sizeMinPx +
          _rng.nextDouble() * (profile.sizeMaxPx - profile.sizeMinPx);
      particles.add(
        TraceParticle(
          position: position,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          bornAtMs: nowMs,
          lifetimeMs: profile.lifetimeMs,
          sizePx: size,
          color: profile.resolveColor(strokeColor) ?? Colors.white,
          startOpacity: profile.startOpacity,
          endOpacity: profile.endOpacity,
        ),
      );
    }
  }

  void tick(int nowMs, {double deltaSeconds = 1 / 60}) {
    particles.removeWhere((p) => !p.isAlive(nowMs));
    for (final particle in particles) {
      particle.velocity = Offset(
        particle.velocity.dx,
        particle.velocity.dy + profile.gravityY * 60 * deltaSeconds,
      );
      particle.position += particle.velocity * deltaSeconds;
    }
  }

  List<TraceParticle> snapshot() => List.unmodifiable(particles);
}
