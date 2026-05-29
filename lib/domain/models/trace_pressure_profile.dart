/// Per-profile pressure capture and rendering settings.
class TracePressureProfile {
  const TracePressureProfile({
    this.enabled = true,
    this.affectsWidth = true,
    this.affectsOpacity = true,
    this.minPressure = 0.25,
    this.maxPressure = 1.0,
    this.startPressure = 0.85,
    this.minWidthPx = 2.5,
    this.maxWidthPx = 6.5,
    this.minOpacity = 0.55,
    this.maxOpacity = 1.0,
    this.speedSlowPxPerSec = 40,
    this.speedFastPxPerSec = 900,
    this.minSampleIntervalMs = 8,
    this.smoothingStrength = 0,
  });

  final bool enabled;
  final bool affectsWidth;
  final bool affectsOpacity;
  final double minPressure;
  final double maxPressure;
  final double startPressure;
  final double minWidthPx;
  final double maxWidthPx;
  final double minOpacity;
  final double maxOpacity;
  final double speedSlowPxPerSec;
  final double speedFastPxPerSec;
  final int minSampleIntervalMs;
  final double smoothingStrength;

  static const defaultWidthPx = 4.0;

  TracePressureProfile copyWith({
    bool? enabled,
    bool? affectsWidth,
    bool? affectsOpacity,
    double? minPressure,
    double? maxPressure,
    double? startPressure,
    double? minWidthPx,
    double? maxWidthPx,
    double? minOpacity,
    double? maxOpacity,
    double? speedSlowPxPerSec,
    double? speedFastPxPerSec,
    int? minSampleIntervalMs,
    double? smoothingStrength,
  }) {
    return TracePressureProfile(
      enabled: enabled ?? this.enabled,
      affectsWidth: affectsWidth ?? this.affectsWidth,
      affectsOpacity: affectsOpacity ?? this.affectsOpacity,
      minPressure: minPressure ?? this.minPressure,
      maxPressure: maxPressure ?? this.maxPressure,
      startPressure: startPressure ?? this.startPressure,
      minWidthPx: minWidthPx ?? this.minWidthPx,
      maxWidthPx: maxWidthPx ?? this.maxWidthPx,
      minOpacity: minOpacity ?? this.minOpacity,
      maxOpacity: maxOpacity ?? this.maxOpacity,
      speedSlowPxPerSec: speedSlowPxPerSec ?? this.speedSlowPxPerSec,
      speedFastPxPerSec: speedFastPxPerSec ?? this.speedFastPxPerSec,
      minSampleIntervalMs: minSampleIntervalMs ?? this.minSampleIntervalMs,
      smoothingStrength: smoothingStrength ?? this.smoothingStrength,
    );
  }

  double widthFor(double pressure) {
    if (!enabled || !affectsWidth) return defaultWidthPx;
    return minWidthPx + pressure.clamp(0.0, 1.0) * (maxWidthPx - minWidthPx);
  }

  double opacityFor(double pressure) {
    if (!enabled || !affectsOpacity) return 1.0;
    return minOpacity + pressure.clamp(0.0, 1.0) * (maxOpacity - minOpacity);
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'affectsWidth': affectsWidth,
        'affectsOpacity': affectsOpacity,
        'minPressure': minPressure,
        'maxPressure': maxPressure,
        'startPressure': startPressure,
        'minWidthPx': minWidthPx,
        'maxWidthPx': maxWidthPx,
        'minOpacity': minOpacity,
        'maxOpacity': maxOpacity,
        'speedSlowPxPerSec': speedSlowPxPerSec,
        'speedFastPxPerSec': speedFastPxPerSec,
        'minSampleIntervalMs': minSampleIntervalMs,
        'smoothingStrength': smoothingStrength,
      };

  factory TracePressureProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TracePressureProfile();
    return TracePressureProfile(
      enabled: json['enabled'] as bool? ?? true,
      affectsWidth: json['affectsWidth'] as bool? ?? true,
      affectsOpacity: json['affectsOpacity'] as bool? ?? true,
      minPressure: (json['minPressure'] as num?)?.toDouble() ?? 0.25,
      maxPressure: (json['maxPressure'] as num?)?.toDouble() ?? 1.0,
      startPressure: (json['startPressure'] as num?)?.toDouble() ?? 0.85,
      minWidthPx: (json['minWidthPx'] as num?)?.toDouble() ?? 2.5,
      maxWidthPx: (json['maxWidthPx'] as num?)?.toDouble() ?? 6.5,
      minOpacity: (json['minOpacity'] as num?)?.toDouble() ?? 0.55,
      maxOpacity: (json['maxOpacity'] as num?)?.toDouble() ?? 1.0,
      speedSlowPxPerSec: (json['speedSlowPxPerSec'] as num?)?.toDouble() ?? 40,
      speedFastPxPerSec: (json['speedFastPxPerSec'] as num?)?.toDouble() ?? 900,
      minSampleIntervalMs: (json['minSampleIntervalMs'] as num?)?.toInt() ?? 8,
      smoothingStrength: (json['smoothingStrength'] as num?)?.toDouble() ?? 0,
    );
  }
}
