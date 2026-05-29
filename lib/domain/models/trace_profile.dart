import 'dart:ui';

import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_playback_profile.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/models/trace_process_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';

/// Live-draw settings: send processing + default playback appearance.
class TraceProfile {
  const TraceProfile({
    this.preset = TraceProfilePreset.littlePrettify,
    this.process = const TraceProcessProfile(),
    this.particles = const ParticleEffectProfile(),
    this.pressure = const TracePressureProfile(),
  });

  final TraceProfilePreset preset;
  final TraceProcessProfile process;
  final ParticleEffectProfile particles;
  final TracePressureProfile pressure;

  double get minPointDistancePx => process.minPointDistancePx;
  double get smoothingStrength => process.smoothingStrength;
  double get simplifyTolerancePx => process.simplifyTolerancePx;
  double get cornerPreservation => process.cornerPreservation;
  double get resampleStepPx => process.resampleStepPx;
  TraceTimingMode get timingMode => process.timingMode;
  double get speedMultiplier => process.speedMultiplier;
  int get targetDurationMs => process.targetDurationMs;
  int get minPointIntervalMs => process.minPointIntervalMs;
  bool get preserveStrokePauses => process.preserveStrokePauses;

  TracePlaybackProfile toPlaybackProfile(Size captureSize) {
    return TracePlaybackProfile.fromTraceProfile(
      preset,
      captureSize,
      particles: particles,
      pressure: pressure,
    );
  }

  TraceProfile copyWith({
    TraceProfilePreset? preset,
    TraceProcessProfile? process,
    ParticleEffectProfile? particles,
    TracePressureProfile? pressure,
  }) {
    return TraceProfile(
      preset: preset ?? this.preset,
      process: process ?? this.process,
      particles: particles ?? this.particles,
      pressure: pressure ?? this.pressure,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.name,
        'process': process.toJson(),
        'particles': particles.toJson(),
        'pressure': pressure.toJson(),
      };

  factory TraceProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TraceProfilePresets.forPreset(TraceProfilePreset.pureFinger);
    }

    final legacyCleanup = json['cleanup'] as Map<String, dynamic>?;
    final legacyTiming = json['timing'] as Map<String, dynamic>?;
    final processJson = json['process'] as Map<String, dynamic>?;
    TraceProcessProfile process;
    if (processJson != null) {
      process = TraceProcessProfile.fromJson(processJson);
    } else if (legacyCleanup != null || legacyTiming != null) {
      process = TraceProcessProfile.fromJson({
        ...?legacyCleanup,
        ...?legacyTiming,
      });
    } else {
      process = const TraceProcessProfile();
    }

    return TraceProfile(
      preset: TraceProfilePreset.fromJson(json['preset']?.toString()),
      process: process,
      particles: ParticleEffectProfile.fromJson(
        json['particles'] as Map<String, dynamic>?,
      ),
      pressure: TracePressureProfile.fromJson(
        json['pressure'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Preset bundles for live draw and send processing.
abstract final class TraceProfilePresets {
  static TraceProfile forPreset(TraceProfilePreset preset) {
    return switch (preset) {
      TraceProfilePreset.pureFinger => pureFinger,
      TraceProfilePreset.littlePrettify => littlePrettify,
      TraceProfilePreset.prettified => prettified,
      TraceProfilePreset.custom => littlePrettify,
    };
  }

  static const pureFinger = TraceProfile(
    preset: TraceProfilePreset.pureFinger,
    process: TraceProcessProfile.pureFinger,
    particles: ParticleEffectProfile(enabled: false, style: ParticleEffectStyle.off),
    pressure: TracePressureProfile(enabled: true, smoothingStrength: 0),
  );

  static const littlePrettify = TraceProfile(
    preset: TraceProfilePreset.littlePrettify,
    process: TraceProcessProfile.littlePrettify,
    particles: ParticleEffectProfile(
      enabled: true,
      style: ParticleEffectStyle.sparkle,
      spawnMode: ParticleSpawnMode.strokeHead,
      density: 0.35,
      spawnIntervalMs: 24,
      particlesPerBurst: 2,
      lifetimeMs: 600,
      sizeMinPx: 1.5,
      sizeMaxPx: 3,
      speedMinPx: 8,
      speedMaxPx: 20,
      spreadAngleDeg: 120,
      gravityY: 2,
      startOpacity: 0.7,
      endOpacity: 0,
      blendWithStrokeFade: true,
    ),
    pressure: TracePressureProfile(enabled: true, smoothingStrength: 0.25),
  );

  static const prettified = TraceProfile(
    preset: TraceProfilePreset.prettified,
    process: TraceProcessProfile.prettified,
    particles: ParticleEffectProfile(
      enabled: true,
      style: ParticleEffectStyle.glow,
      spawnMode: ParticleSpawnMode.strokeTrail,
      density: 0.65,
      spawnIntervalMs: 16,
      particlesPerBurst: 4,
      lifetimeMs: 900,
      sizeMinPx: 2.5,
      sizeMaxPx: 5,
      speedMinPx: 12,
      speedMaxPx: 32,
      spreadAngleDeg: 180,
      gravityY: 4,
      startOpacity: 0.85,
      endOpacity: 0.1,
      blendWithStrokeFade: true,
    ),
    pressure: TracePressureProfile(
      enabled: true,
      smoothingStrength: 0.5,
      minWidthPx: 2,
      maxWidthPx: 8,
    ),
  );
}
