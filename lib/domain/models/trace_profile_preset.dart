/// User-facing trace style presets.
enum TraceProfilePreset {
  pureFinger,
  littlePrettify,
  prettified,
  custom;

  String get label => switch (this) {
        pureFinger => 'Pure Finger',
        littlePrettify => 'A Little Prettify',
        prettified => 'Prettified',
        custom => 'Custom',
      };

  String get description => switch (this) {
        pureFinger => 'Draw and display as-is. Best if you are confident with finger drawing.',
        littlePrettify => 'Balanced for most users. Slightly smoothed with subtle sparkle.',
        prettified => 'Heavily normalized and smoothed, with glow particles.',
        custom => 'Your saved custom trace and particle settings.',
      };

  static TraceProfilePreset fromJson(String? raw) {
    return TraceProfilePreset.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => TraceProfilePreset.littlePrettify,
    );
  }
}
