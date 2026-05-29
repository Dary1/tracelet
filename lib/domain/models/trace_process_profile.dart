enum TraceTimingMode { wallClock, compressed, fixedDuration }

/// Send-time trace cleanup and timing (not needed for message playback).
class TraceProcessProfile {
  const TraceProcessProfile({
    this.minPointDistancePx = 1.5,
    this.smoothingStrength = 0.25,
    this.simplifyTolerancePx = 2,
    this.cornerPreservation = 0.7,
    this.resampleStepPx = 2,
    this.timingMode = TraceTimingMode.compressed,
    this.speedMultiplier = 1,
    this.targetDurationMs = 2500,
    this.minPointIntervalMs = 8,
    this.preserveStrokePauses = true,
  });

  final double minPointDistancePx;
  final double smoothingStrength;
  final double simplifyTolerancePx;
  final double cornerPreservation;
  final double resampleStepPx;
  final TraceTimingMode timingMode;
  final double speedMultiplier;
  final int targetDurationMs;
  final int minPointIntervalMs;
  final bool preserveStrokePauses;

  static const pureFinger = TraceProcessProfile(
    minPointDistancePx: 0,
    smoothingStrength: 0,
    simplifyTolerancePx: 0,
    cornerPreservation: 1,
    resampleStepPx: 0,
    timingMode: TraceTimingMode.wallClock,
    minPointIntervalMs: 0,
  );

  static const littlePrettify = TraceProcessProfile();

  static const prettified = TraceProcessProfile(
    minPointDistancePx: 3,
    smoothingStrength: 0.75,
    simplifyTolerancePx: 6,
    cornerPreservation: 0.3,
    resampleStepPx: 3,
    timingMode: TraceTimingMode.fixedDuration,
    targetDurationMs: 2500,
    minPointIntervalMs: 12,
    preserveStrokePauses: false,
  );

  TraceProcessProfile copyWith({
    double? minPointDistancePx,
    double? smoothingStrength,
    double? simplifyTolerancePx,
    double? cornerPreservation,
    double? resampleStepPx,
    TraceTimingMode? timingMode,
    double? speedMultiplier,
    int? targetDurationMs,
    int? minPointIntervalMs,
    bool? preserveStrokePauses,
  }) {
    return TraceProcessProfile(
      minPointDistancePx: minPointDistancePx ?? this.minPointDistancePx,
      smoothingStrength: smoothingStrength ?? this.smoothingStrength,
      simplifyTolerancePx: simplifyTolerancePx ?? this.simplifyTolerancePx,
      cornerPreservation: cornerPreservation ?? this.cornerPreservation,
      resampleStepPx: resampleStepPx ?? this.resampleStepPx,
      timingMode: timingMode ?? this.timingMode,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      targetDurationMs: targetDurationMs ?? this.targetDurationMs,
      minPointIntervalMs: minPointIntervalMs ?? this.minPointIntervalMs,
      preserveStrokePauses: preserveStrokePauses ?? this.preserveStrokePauses,
    );
  }

  Map<String, dynamic> toJson() => {
        'minPointDistancePx': minPointDistancePx,
        'smoothingStrength': smoothingStrength,
        'simplifyTolerancePx': simplifyTolerancePx,
        'cornerPreservation': cornerPreservation,
        'resampleStepPx': resampleStepPx,
        'timingMode': timingMode.name,
        'speedMultiplier': speedMultiplier,
        'targetDurationMs': targetDurationMs,
        'minPointIntervalMs': minPointIntervalMs,
        'preserveStrokePauses': preserveStrokePauses,
      };

  factory TraceProcessProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TraceProcessProfile();
    return TraceProcessProfile(
      minPointDistancePx: (json['minPointDistancePx'] as num?)?.toDouble() ?? 1.5,
      smoothingStrength: (json['smoothingStrength'] as num?)?.toDouble() ?? 0.25,
      simplifyTolerancePx: (json['simplifyTolerancePx'] as num?)?.toDouble() ?? 2,
      cornerPreservation: (json['cornerPreservation'] as num?)?.toDouble() ?? 0.7,
      resampleStepPx: (json['resampleStepPx'] as num?)?.toDouble() ?? 2,
      timingMode: _timingFromJson(json['timingMode']?.toString()),
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1,
      targetDurationMs: (json['targetDurationMs'] as num?)?.toInt() ?? 2500,
      minPointIntervalMs: (json['minPointIntervalMs'] as num?)?.toInt() ?? 8,
      preserveStrokePauses: json['preserveStrokePauses'] as bool? ?? true,
    );
  }
}

TraceTimingMode _timingFromJson(String? raw) {
  if (raw == null) return TraceTimingMode.compressed;
  for (final mode in TraceTimingMode.values) {
    if (mode.name == raw) return mode;
  }
  return TraceTimingMode.compressed;
}
