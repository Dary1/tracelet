import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _userIdKey = 'tracelet_user_id';

/// Persists a stable dev user id until Cognito auth is wired.
class TraceletSession {
  TraceletSession(this._prefs);

  final SharedPreferences _prefs;

  String? _userId;

  String get userId {
    final id = _userId ?? _prefs.getString(_userIdKey);
    if (id == null || id.isEmpty) {
      throw StateError('Call ensureUserId() before accessing userId.');
    }
    return id;
  }

  String? get userIdOrNull => _userId ?? _prefs.getString(_userIdKey);

  Future<String> ensureUserId() async {
    final existing = _prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) {
      _userId = existing;
      return existing;
    }

    final created = _generateUuidV4();
    await _prefs.setString(_userIdKey, created);
    _userId = created;
    return created;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
