import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';

TraceProfile resolveTraceProfile(AppSettings settings) {
  if (settings.traceProfilePreset == TraceProfilePreset.custom &&
      settings.customTraceProfile != null) {
    return settings.customTraceProfile!;
  }
  return TraceProfilePresets.forPreset(settings.traceProfilePreset);
}
