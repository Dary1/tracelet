import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/traces/particle_emitter.dart';

void main() {
  group('ParticleEmitter', () {
    test('spawns particles when enabled', () {
      final emitter = ParticleEmitter(
        profile: const ParticleEffectProfile(
          enabled: true,
          density: 1,
          particlesPerBurst: 2,
          spawnIntervalMs: 0,
          seed: 42,
        ),
      );

      emitter.onStrokeHead(
        position: const Offset(10, 10),
        tangent: const Offset(1, 0),
        strokeColor: Colors.white,
        nowMs: 0,
        densityScale: 1,
      );

      expect(emitter.particles, hasLength(2));
    });

    test('does not spawn when disabled', () {
      final emitter = ParticleEmitter(
        profile: const ParticleEffectProfile(enabled: false),
      );

      emitter.onStrokeHead(
        position: const Offset(10, 10),
        tangent: null,
        strokeColor: Colors.white,
        nowMs: 0,
      );

      expect(emitter.particles, isEmpty);
    });

    test('removes expired particles on tick', () {
      final emitter = ParticleEmitter(
        profile: const ParticleEffectProfile(
          enabled: true,
          density: 1,
          particlesPerBurst: 1,
          spawnIntervalMs: 0,
          lifetimeMs: 100,
          seed: 1,
        ),
      );

      emitter.onStrokeHead(
        position: Offset.zero,
        tangent: null,
        strokeColor: Colors.white,
        nowMs: 0,
      );
      expect(emitter.particles, hasLength(1));

      emitter.tick(200);
      expect(emitter.particles, isEmpty);
    });
  });
}
