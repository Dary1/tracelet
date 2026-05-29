import 'package:tracelet/domain/models/app_settings.dart';

/// Contract for local/remote settings persistence.
abstract interface class SettingsRepository {
  Future<AppSettings> loadSettings();

  Future<void> saveSettings(AppSettings settings);
}
