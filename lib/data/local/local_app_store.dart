import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet/data/api/trace_payload_codec.dart';
import 'package:tracelet/domain/models/app_settings.dart';
import 'package:tracelet/domain/models/trace_message.dart';
import 'package:tracelet/domain/models/trace_profile.dart';
import 'package:tracelet/domain/models/trace_profile_preset.dart';
import 'package:tracelet/domain/models/user.dart';
import 'package:tracelet/domain/repositories/message_inbox.dart';

const _settingsKey = 'tracelet_local_settings';
const _inboxKey = 'tracelet_message_inbox';

/// Client-only settings fields and persisted message inbox.
class LocalAppStore implements MessageInbox {
  LocalAppStore(this._prefs);

  final SharedPreferences _prefs;

  Future<AppSettings> loadLocalSettings(AppSettings serverSettings) async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return serverSettings;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return serverSettings.copyWith(
        isSubscribed: json['isSubscribed'] as bool? ?? serverSettings.isSubscribed,
        autoPlayEnabled:
            json['autoPlayEnabled'] as bool? ?? serverSettings.autoPlayEnabled,
        autoContinuousReceiveEnabled: json['autoContinuousReceiveEnabled'] as bool? ??
            serverSettings.autoContinuousReceiveEnabled,
        dailyRandomReceiveCount: json['dailyRandomReceiveCount'] as int? ??
            serverSettings.dailyRandomReceiveCount,
        traceProfilePreset: TraceProfilePreset.fromJson(
          json['traceProfilePreset']?.toString(),
        ),
        customTraceProfile: json['customTraceProfile'] is Map<String, dynamic>
            ? TraceProfile.fromJson(json['customTraceProfile'] as Map<String, dynamic>)
            : serverSettings.customTraceProfile,
      );
    } catch (_) {
      return serverSettings;
    }
  }

  Future<void> saveLocalSettings(AppSettings settings) async {
    await _prefs.setString(
      _settingsKey,
      jsonEncode({
        'isSubscribed': settings.isSubscribed,
        'autoPlayEnabled': settings.autoPlayEnabled,
        'autoContinuousReceiveEnabled': settings.autoContinuousReceiveEnabled,
        'dailyRandomReceiveCount': settings.dailyRandomReceiveCount,
        'traceProfilePreset': settings.traceProfilePreset.name,
        if (settings.customTraceProfile != null)
          'customTraceProfile': settings.customTraceProfile!.toJson(),
      }),
    );
  }

  @override
  Future<List<TraceMessage>> readAll() async {
    final raw = _prefs.getString(_inboxKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map(_decodeMessage).whereType<TraceMessage>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> writeAll(List<TraceMessage> messages) async {
    await _prefs.setString(
      _inboxKey,
      jsonEncode(messages.map(_encodeMessage).toList()),
    );
  }

  static Map<String, dynamic> _encodeMessage(TraceMessage message) {
    return {
      'id': message.id,
      'senderId': message.sender.id,
      'senderDisplayName': message.sender.displayName,
      'senderIsAiPersona': message.sender.isAiPersona,
      'receivedAt': message.receivedAt.toIso8601String(),
      'played': message.played,
      'isLegacyPayload': message.isLegacyPayload,
      'payload': TracePayloadCodec.encodePayload(
        points: message.points,
        playback: message.playbackProfile,
      ),
    };
  }

  static TraceMessage? _decodeMessage(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    Map<String, dynamic>? payload;
    if (raw['payload'] is Map<String, dynamic>) {
      payload = raw['payload'] as Map<String, dynamic>;
    } else if (raw['points'] != null) {
      payload = {'points': raw['points']};
    }

    final decoded = TracePayloadCodec.decodePayload(payload);
    final playbackProfile = decoded.playbackProfile;

    return TraceMessage(
      id: raw['id']?.toString() ?? '',
      sender: TraceUser(
        id: raw['senderId']?.toString() ?? 'unknown',
        displayName: raw['senderDisplayName']?.toString() ?? 'Unknown',
        isAiPersona: raw['senderIsAiPersona'] as bool? ?? false,
      ),
      receivedAt: DateTime.tryParse(raw['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      played: raw['played'] as bool? ?? false,
      points: decoded.points,
      playbackProfile: playbackProfile,
      isLegacyPayload: raw['isLegacyPayload'] as bool? ?? decoded.isLegacy,
    );
  }

  @visibleForTesting
  static TraceMessage? decodeStoredMessage(Object? raw) => _decodeMessage(raw);
}
