import 'package:tracelet/domain/system_traces/system_trace_id.dart';
import 'package:tracelet/domain/system_traces/system_trace_theme_id.dart';

/// Asset paths for theme-scoped system trace JSON files.
abstract final class SystemTracePaths {
  static const root = 'assets/system_traces';

  static String directoryFor(SystemTraceThemeId theme) =>
      '$root/${theme.folderName}';

  static String assetPath(SystemTraceThemeId theme, SystemTraceId id) =>
      '${directoryFor(theme)}/${id.name}.json';
}
