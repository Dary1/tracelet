import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/data/local/local_app_store.dart';
import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/repositories/settings_repository.dart';

class AwsSettingsRepository implements SettingsRepository {
  AwsSettingsRepository(this._api, this._local);

  final TraceletApiClient _api;
  final LocalAppStore _local;

  @override
  Future<AppSettings> loadSettings() async {
    final body = await _api.get('/settings');
    final server = AppSettings(
      defaultPenColor: body['defaultPenColor']?.toString() ?? '#007AFF',
      notificationsEnabled: body['notificationsEnabled'] as bool? ?? true,
      muted: body['muted'] as bool? ?? false,
    );
    return _local.loadLocalSettings(server);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _api.put('/settings', {
      'defaultPenColor': settings.defaultPenColor,
      'notificationsEnabled': settings.notificationsEnabled,
      'muted': settings.muted,
    });
    await _local.saveLocalSettings(settings);
  }
}
