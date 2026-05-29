import 'dart:convert';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:tracelet/core/backend_config.dart';
import 'package:tracelet/data/auth/cognito_auth_service.dart';
import 'package:tracelet/domain/auth/auth_state.dart';
import 'package:tracelet/domain/auth/social_provider.dart';
import 'package:tracelet/domain/auth/social_sign_in_unavailable_exception.dart';

class CognitoHostedUiAuth {
  CognitoHostedUiAuth({
    required CognitoAuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _http = httpClient ?? http.Client();

  final CognitoAuthService _authService;
  final http.Client _http;

  bool get isGoogleConfigured => BackendConfig.googleSignInEnabled;

  bool get isAppleConfigured => BackendConfig.appleSignInEnabled;

  bool isConfigured(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => isGoogleConfigured,
      SocialProvider.apple => isAppleConfigured,
    };
  }

  Future<AuthState> signIn(SocialProvider provider) async {
    if (!isConfigured(provider)) {
      throw SocialSignInUnavailableException(provider);
    }

    final redirectUri = BackendConfig.oauthRedirectUri;
    final authorizeUri = Uri.https(
      BackendConfig.cognitoHostedUiDomain,
      '/oauth2/authorize',
      {
        'client_id': BackendConfig.cognitoUserPoolClientId,
        'response_type': 'code',
        'scope': 'openid email profile',
        'redirect_uri': redirectUri,
        'identity_provider': provider.cognitoIdpName,
      },
    );

    final callbackUri = await FlutterWebAuth2.authenticate(
      url: authorizeUri.toString(),
      callbackUrlScheme: BackendConfig.oauthCallbackScheme,
    );

    final code = Uri.parse(callbackUri).queryParameters['code'];
    if (code == null || code.isEmpty) {
      return AuthState(
        status: AuthStatus.guest,
        errorMessage: 'Sign in was cancelled',
      );
    }

    final tokenResponse = await _http.post(
      Uri.https(BackendConfig.cognitoHostedUiDomain, '/oauth2/token'),
      headers: {'content-type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': BackendConfig.cognitoUserPoolClientId,
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (tokenResponse.statusCode >= 400) {
      return AuthState(
        status: AuthStatus.guest,
        errorMessage: 'Sign in failed (${tokenResponse.statusCode})',
      );
    }

    final tokens = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final idToken = tokens['id_token']?.toString();
    final accessToken = tokens['access_token']?.toString();
    final refreshToken = tokens['refresh_token']?.toString();
    if (idToken == null || accessToken == null || refreshToken == null) {
      return AuthState(
        status: AuthStatus.guest,
        errorMessage: 'Incomplete sign-in response',
      );
    }

    return _authService.persistOAuthTokens(
      idToken: idToken,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
