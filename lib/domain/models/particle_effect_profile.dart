import 'package:flutter/material.dart';

enum ParticleEffectStyle { off, sparkle, glow, drift, ember }

enum ParticleSpawnMode { strokeHead, strokeTrail, wholeStroke }

/// Procedural particle params stored in trace header (no particle positions).
class ParticleEffectProfile {
  const ParticleEffectProfile({
    this.enabled = false,
    this.style = ParticleEffectStyle.off,
    this.spawnMode = ParticleSpawnMode.strokeHead,
    this.density = 0,
    this.spawnIntervalMs = 24,
    this.particlesPerBurst = 0,
    this.lifetimeMs = 600,
    this.sizeMinPx = 1.5,
    this.sizeMaxPx = 3,
    this.speedMinPx = 8,
    this.speedMaxPx = 20,
    this.spreadAngleDeg = 120,
    this.gravityY = 2,
    this.inheritStrokeColor = true,
    this.colorOverride,
    this.startOpacity = 0.7,
    this.endOpacity = 0,
    this.blendWithStrokeFade = true,
    this.seed,
  });

  final bool enabled;
  final ParticleEffectStyle style;
  final ParticleSpawnMode spawnMode;
  final double density;
  final int spawnIntervalMs;
  final int particlesPerBurst;
  final int lifetimeMs;
  final double sizeMinPx;
  final double sizeMaxPx;
  final double speedMinPx;
  final double speedMaxPx;
  final double spreadAngleDeg;
  final double gravityY;
  final bool inheritStrokeColor;
  final String? colorOverride;
  final double startOpacity;
  final double endOpacity;
  final bool blendWithStrokeFade;
  final int? seed;

  ParticleEffectProfile copyWith({
    bool? enabled,
    ParticleEffectStyle? style,
    ParticleSpawnMode? spawnMode,
    double? density,
    int? spawnIntervalMs,
    int? particlesPerBurst,
    int? lifetimeMs,
    double? sizeMinPx,
    double? sizeMaxPx,
    double? speedMinPx,
    double? speedMaxPx,
    double? spreadAngleDeg,
    double? gravityY,
    bool? inheritStrokeColor,
    String? colorOverride,
    double? startOpacity,
    double? endOpacity,
    bool? blendWithStrokeFade,
    int? seed,
  }) {
    return ParticleEffectProfile(
      enabled: enabled ?? this.enabled,
      style: style ?? this.style,
      spawnMode: spawnMode ?? this.spawnMode,
      density: density ?? this.density,
      spawnIntervalMs: spawnIntervalMs ?? this.spawnIntervalMs,
      particlesPerBurst: particlesPerBurst ?? this.particlesPerBurst,
      lifetimeMs: lifetimeMs ?? this.lifetimeMs,
      sizeMinPx: sizeMinPx ?? this.sizeMinPx,
      sizeMaxPx: sizeMaxPx ?? this.sizeMaxPx,
      speedMinPx: speedMinPx ?? this.speedMinPx,
      speedMaxPx: speedMaxPx ?? this.speedMaxPx,
      spreadAngleDeg: spreadAngleDeg ?? this.spreadAngleDeg,
      gravityY: gravityY ?? this.gravityY,
      inheritStrokeColor: inheritStrokeColor ?? this.inheritStrokeColor,
      colorOverride: colorOverride ?? this.colorOverride,
      startOpacity: startOpacity ?? this.startOpacity,
      endOpacity: endOpacity ?? this.endOpacity,
      blendWithStrokeFade: blendWithStrokeFade ?? this.blendWithStrokeFade,
      seed: seed ?? this.seed,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'style': style.name,
        'spawnMode': spawnMode.name,
        'density': density,
        'spawnIntervalMs': spawnIntervalMs,
        'particlesPerBurst': particlesPerBurst,
        'lifetimeMs': lifetimeMs,
        'sizeMinPx': sizeMinPx,
        'sizeMaxPx': sizeMaxPx,
        'speedMinPx': speedMinPx,
        'speedMaxPx': speedMaxPx,
        'spreadAngleDeg': spreadAngleDeg,
        'gravityY': gravityY,
        'inheritStrokeColor': inheritStrokeColor,
        if (colorOverride != null) 'colorOverride': colorOverride,
        'startOpacity': startOpacity,
        'endOpacity': endOpacity,
        'blendWithStrokeFade': blendWithStrokeFade,
        if (seed != null) 'seed': seed,
      };

  factory ParticleEffectProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ParticleEffectProfile();
    return ParticleEffectProfile(
      enabled: json['enabled'] as bool? ?? false,
      style: _enumByName(
        ParticleEffectStyle.values,
        json['style']?.toString(),
        ParticleEffectStyle.off,
      ),
      spawnMode: _enumByName(
        ParticleSpawnMode.values,
        json['spawnMode']?.toString(),
        ParticleSpawnMode.strokeHead,
      ),
      density: (json['density'] as num?)?.toDouble() ?? 0,
      spawnIntervalMs: (json['spawnIntervalMs'] as num?)?.toInt() ?? 24,
      particlesPerBurst: (json['particlesPerBurst'] as num?)?.toInt() ?? 0,
      lifetimeMs: (json['lifetimeMs'] as num?)?.toInt() ?? 600,
      sizeMinPx: (json['sizeMinPx'] as num?)?.toDouble() ?? 1.5,
      sizeMaxPx: (json['sizeMaxPx'] as num?)?.toDouble() ?? 3,
      speedMinPx: (json['speedMinPx'] as num?)?.toDouble() ?? 8,
      speedMaxPx: (json['speedMaxPx'] as num?)?.toDouble() ?? 20,
      spreadAngleDeg: (json['spreadAngleDeg'] as num?)?.toDouble() ?? 120,
      gravityY: (json['gravityY'] as num?)?.toDouble() ?? 2,
      inheritStrokeColor: json['inheritStrokeColor'] as bool? ?? true,
      colorOverride: json['colorOverride']?.toString(),
      startOpacity: (json['startOpacity'] as num?)?.toDouble() ?? 0.7,
      endOpacity: (json['endOpacity'] as num?)?.toDouble() ?? 0,
      blendWithStrokeFade: json['blendWithStrokeFade'] as bool? ?? true,
      seed: (json['seed'] as num?)?.toInt(),
    );
  }

  Color? resolveColor(Color? strokeColor) {
    if (!inheritStrokeColor && colorOverride != null) {
      final hex = colorOverride!.replaceFirst('#', '');
      if (hex.length == 6) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) return Color(0xFF000000 | value);
      }
    }
    return strokeColor;
  }
}

T _enumByName<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}
