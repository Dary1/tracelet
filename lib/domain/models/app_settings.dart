import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';

/// Persisted user preferences (mute, subscription, etc.).
class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.muted = false,
    this.defaultPenColor = '#007AFF',
    this.isSubscribed = false,
    this.autoPlayEnabled = false,
    this.autoContinuousReceiveEnabled = false,
    this.dailyRandomReceiveCount = 0,
    this.traceProfilePreset = TraceProfilePreset.littlePrettify,
    this.customTraceProfile,
  });

  final bool notificationsEnabled;
  final bool muted;
  final String defaultPenColor;
  final bool isSubscribed;
  final bool autoPlayEnabled;
  final bool autoContinuousReceiveEnabled;
  final int dailyRandomReceiveCount;
  final TraceProfilePreset traceProfilePreset;
  final TraceProfile? customTraceProfile;

  int get dailyRandomReceiveLimit => isSubscribed ? 100 : 10;

  bool get canReceiveRandomMessage =>
      dailyRandomReceiveCount < dailyRandomReceiveLimit;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? muted,
    String? defaultPenColor,
    bool? isSubscribed,
    bool? autoPlayEnabled,
    bool? autoContinuousReceiveEnabled,
    int? dailyRandomReceiveCount,
    TraceProfilePreset? traceProfilePreset,
    TraceProfile? customTraceProfile,
  }) {
    return AppSettings(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      muted: muted ?? this.muted,
      defaultPenColor: defaultPenColor ?? this.defaultPenColor,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      autoContinuousReceiveEnabled:
          autoContinuousReceiveEnabled ?? this.autoContinuousReceiveEnabled,
      dailyRandomReceiveCount:
          dailyRandomReceiveCount ?? this.dailyRandomReceiveCount,
      traceProfilePreset: traceProfilePreset ?? this.traceProfilePreset,
      customTraceProfile: customTraceProfile ?? this.customTraceProfile,
    );
  }
}
