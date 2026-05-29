import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet/core/backend_config.dart';
import 'package:tracelet/domain/auth/api_auth_context.dart';
import 'package:tracelet/domain/auth/auth_state.dart';

const _storageKeySubject = 'tracelet_auth_subject';
const _storageKeyIdToken = 'tracelet_auth_id_token';
const _storageKeyAccessToken = 'tracelet_auth_access_token';
const _storageKeyRefreshToken = 'tracelet_auth_refresh_token';
const _storageKeyUserId = 'tracelet_auth_user_id';
const _storageKeyDisplayName = 'tracelet_auth_display_name';

class CognitoAuthService implements ApiAuthContext {
  CognitoAuthService(this._prefs)
      : _userPool = CognitoUserPool(
          BackendConfig.cognitoUserPoolId,
          BackendConfig.cognitoUserPoolClientId,
        );

  final SharedPreferences _prefs;
  final CognitoUserPool _userPool;

  AuthSession? _session;

  AuthSession? get currentSession => _session;

  Future<AuthState?> restoreSocialSession() async {
    final refreshToken = _prefs.getString(_storageKeyRefreshToken);
    final subject = _prefs.getString(_storageKeySubject);
    if (refreshToken == null || subject == null) {
      _session = null;
      return null;
    }

    try {
      final user = CognitoUser(subject, _userPool);
      final session =
          await user.refreshSession(CognitoRefreshToken(refreshToken));
      if (session == null) {
        await _clearStoredSession();
        return null;
      }
      return _persistCognitoSession(subject, session);
    } catch (_) {
      final stored = await _loadStoredSession();
      if (stored != null) {
        _session = stored;
        return AuthState.social(stored);
      }
      await _clearStoredSession();
      return null;
    }
  }

  Future<AuthState> persistOAuthTokens({
    required String idToken,
    required String accessToken,
    required String refreshToken,
  }) async {
    final claims = _claimsFromIdToken(idToken);
    final subject = claims['sub']?.toString() ?? '';
    if (subject.isEmpty) {
      return const AuthState(errorMessage: 'Invalid sign-in token');
    }

    await _prefs.setString(_storageKeySubject, subject);
    await _prefs.setString(_storageKeyIdToken, idToken);
    await _prefs.setString(_storageKeyAccessToken, accessToken);
    await _prefs.setString(_storageKeyRefreshToken, refreshToken);
    await _prefs.setString(_storageKeyUserId, subject);

    final displayName = claims['name']?.toString() ??
        claims['email']?.toString() ??
        'Signed in';
    await _prefs.setString(_storageKeyDisplayName, displayName);

    _session = AuthSession(
      userId: subject,
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      displayName: displayName,
    );

    return AuthState.social(_session!);
  }

  Future<void> signOut() async {
    final subject = _prefs.getString(_storageKeySubject);
    if (subject != null) {
      final user = CognitoUser(subject, _userPool);
      try {
        await user.signOut();
      } catch (_) {
        // Local session clear still proceeds.
      }
    }
    await _clearStoredSession();
    _session = null;
  }

  @override
  String? get userId => _session?.userId ?? _prefs.getString(_storageKeyUserId);

  @override
  Future<String?> bearerToken() async {
    _session ??= await _loadStoredSession();
    return _session?.idToken;
  }

  Future<AuthState> _persistCognitoSession(
    String subject,
    CognitoUserSession session,
  ) async {
    final idToken = session.getIdToken().getJwtToken();
    final accessToken = session.getAccessToken().getJwtToken();
    final refreshToken = session.getRefreshToken()?.getToken();

    if (idToken == null || accessToken == null || refreshToken == null) {
      return const AuthState(errorMessage: 'Incomplete Cognito session');
    }

    return persistOAuthTokens(
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AuthSession?> _loadStoredSession() async {
    final idToken = _prefs.getString(_storageKeyIdToken);
    final accessToken = _prefs.getString(_storageKeyAccessToken);
    final refreshToken = _prefs.getString(_storageKeyRefreshToken);
    final userId = _prefs.getString(_storageKeyUserId);
    if (idToken == null ||
        accessToken == null ||
        refreshToken == null ||
        userId == null) {
      return null;
    }
    return AuthSession(
      userId: userId,
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
      displayName: _prefs.getString(_storageKeyDisplayName),
    );
  }

  Future<void> _clearStoredSession() async {
    await _prefs.remove(_storageKeySubject);
    await _prefs.remove(_storageKeyIdToken);
    await _prefs.remove(_storageKeyAccessToken);
    await _prefs.remove(_storageKeyRefreshToken);
    await _prefs.remove(_storageKeyUserId);
    await _prefs.remove(_storageKeyDisplayName);
  }

  Map<String, dynamic> _claimsFromIdToken(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return {};
    final normalized = base64Url.normalize(parts[1]);
    final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return {};
  }
}
