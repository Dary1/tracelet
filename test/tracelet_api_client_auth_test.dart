import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/domain/auth/api_auth_context.dart';
import 'package:tracelet/domain/auth/auth_required_exception.dart';

class FakeAuthContext implements ApiAuthContext {
  FakeAuthContext({this.token, this.userId = 'user-1'});

  String? token;
  @override
  String? userId;

  @override
  Future<String?> bearerToken() async => token;
}

void main() {
  group('TraceletApiClient auth', () {
    test('guest sends x-user-id without bearer token', () async {
      String? userIdHeader;
      final client = TraceletApiClient(
        auth: FakeAuthContext(token: null, userId: 'guest-123'),
        httpClient: MockClient((request) async {
          userIdHeader = request.headers['x-user-id'];
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
        baseUrl: 'https://example.test',
      );

      await client.get('/settings');

      expect(userIdHeader, 'guest-123');
    });

    test('throws AuthRequiredException when no identity is available', () async {
      final client = TraceletApiClient(
        auth: FakeAuthContext(token: null, userId: null),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: 'https://example.test',
      );

      expect(
        () => client.get('/settings'),
        throwsA(isA<AuthRequiredException>()),
      );
    });

    test('sends Authorization bearer header when authenticated', () async {
      String? authorization;
      final client = TraceletApiClient(
        auth: FakeAuthContext(token: 'jwt-token', userId: 'cognito-sub'),
        httpClient: MockClient((request) async {
          authorization = request.headers['authorization'];
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
        baseUrl: 'https://example.test',
      );

      await client.get('/settings');

      expect(authorization, 'Bearer jwt-token');
    });

    test('maps HTTP 401 to AuthRequiredException', () async {
      final client = TraceletApiClient(
        auth: FakeAuthContext(token: 'expired', userId: 'user-1'),
        httpClient: MockClient(
          (_) async => http.Response('{"message":"Unauthorized"}', 401),
        ),
        baseUrl: 'https://example.test',
      );

      expect(
        () => client.post('/bottles', {'payload': []}),
        throwsA(isA<AuthRequiredException>()),
      );
    });
  });
}
