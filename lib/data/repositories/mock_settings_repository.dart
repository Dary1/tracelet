import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/repositories/settings_repository.dart';

/// In-memory mock for development until AWS backend is wired.
class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}
