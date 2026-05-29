/// Identifies a themed set of system-defined trace assets.
///
/// Each value maps to `assets/system_traces/<folderName>/`.
/// Register new theme folders in [pubspec.yaml] under `flutter.assets`.
enum SystemTraceThemeId {
  defaultTheme('default');

  const SystemTraceThemeId(this.folderName);

  final String folderName;

  /// Trace theme paired with the built-in UI theme.
  static const active = SystemTraceThemeId.defaultTheme;
}
