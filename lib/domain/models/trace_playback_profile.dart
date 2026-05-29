import 'dart:ui';

import 'package:tracelet/domain/models/particle_effect_profile.dart';
import 'package:tracelet/domain/models/trace_coordinate_space.dart';
import 'package:tracelet/domain/models/trace_pressure_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';

/// Rendering snapshot for message playback (embedded in bottle payload v2).
class TracePlaybackProfile {
  const TracePlaybackProfile({
    this.profileVersion = currentVersion,
    this.preset = TraceProfilePreset.littlePrettify,
    required this.captureWidth,
    required this.captureHeight,
    this.coordinateSpace = TraceCoordinateSpace.normalized,
    this.particles = const ParticleEffectProfile(),
    this.pressure = const TracePressureProfile(),
  });

  static const currentVersion = 2;
  static const legacyVersion = 1;

  final int profileVersion;
  final TraceProfilePreset preset;
  final double captureWidth;
  final double captureHeight;
  final TraceCoordinateSpace coordinateSpace;
  final ParticleEffectProfile particles;
  final TracePressureProfile pressure;

  bool get isNormalized => coordinateSpace == TraceCoordinateSpace.normalized;

  TracePlaybackProfile copyWith({
    int? profileVersion,
    TraceProfilePreset? preset,
    double? captureWidth,
    double? captureHeight,
    TraceCoordinateSpace? coordinateSpace,
    ParticleEffectProfile? particles,
    TracePressureProfile? pressure,
  }) {
    return TracePlaybackProfile(
      profileVersion: profileVersion ?? this.profileVersion,
      preset: preset ?? this.preset,
      captureWidth: captureWidth ?? this.captureWidth,
      captureHeight: captureHeight ?? this.captureHeight,
      coordinateSpace: coordinateSpace ?? this.coordinateSpace,
      particles: particles ?? this.particles,
      pressure: pressure ?? this.pressure,
    );
  }

  TracePlaybackProfile withCaptureSize(Size size) {
    return copyWith(captureWidth: size.width, captureHeight: size.height);
  }

  /// System-authored traces: normalized geometry, user appearance at play time.
  factory TracePlaybackProfile.forSystemTrace({
    required Size canvasSize,
    required TraceProfilePreset preset,
    required ParticleEffectProfile particles,
    required TracePressureProfile pressure,
  }) {
    return TracePlaybackProfile(
      preset: preset,
      captureWidth: canvasSize.width,
      captureHeight: canvasSize.height,
      coordinateSpace: TraceCoordinateSpace.normalized,
      particles: particles,
      pressure: pressure,
    );
  }

  factory TracePlaybackProfile.fromTraceProfile(
    TraceProfilePreset preset,
    Size captureSize, {
    required ParticleEffectProfile particles,
    required TracePressureProfile pressure,
  }) {
    return TracePlaybackProfile(
      preset: preset,
      captureWidth: captureSize.width,
      captureHeight: captureSize.height,
      coordinateSpace: TraceCoordinateSpace.normalized,
      particles: particles,
      pressure: pressure,
    );
  }

  factory TracePlaybackProfile.fromLegacyPayload({
    required TraceProfilePreset preset,
    required double captureWidth,
    required double captureHeight,
    required TraceCoordinateSpace coordinateSpace,
    required ParticleEffectProfile particles,
    required TracePressureProfile pressure,
  }) {
    return TracePlaybackProfile(
      profileVersion: legacyVersion,
      preset: preset,
      captureWidth: captureWidth,
      captureHeight: captureHeight,
      coordinateSpace: coordinateSpace,
      particles: particles,
      pressure: pressure,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.name,
        'captureSize': {'w': captureWidth, 'h': captureHeight},
        'particles': particles.toJson(),
        'pressure': pressure.toJson(),
      };

  factory TracePlaybackProfile.fromJson(
    Map<String, dynamic>? json, {
    int profileVersion = currentVersion,
  }) {
    if (json == null) {
      return TracePlaybackProfile(
        captureWidth: 1,
        captureHeight: 1,
        profileVersion: profileVersion,
      );
    }

    final capture = json['captureSize'] as Map<String, dynamic>?;
    return TracePlaybackProfile(
      profileVersion: profileVersion,
      preset: TraceProfilePreset.fromJson(json['preset']?.toString()),
      captureWidth: (capture?['w'] as num?)?.toDouble() ?? 1,
      captureHeight: (capture?['h'] as num?)?.toDouble() ?? 1,
      coordinateSpace: json['coordinateSpace'] == 'absolute'
          ? TraceCoordinateSpace.absolute
          : TraceCoordinateSpace.normalized,
      particles: ParticleEffectProfile.fromJson(
        json['particles'] as Map<String, dynamic>?,
      ),
      pressure: TracePressureProfile.fromJson(
        json['pressure'] as Map<String, dynamic>?,
      ),
    );
  }
}
