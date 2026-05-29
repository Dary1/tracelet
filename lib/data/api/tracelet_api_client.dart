import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tracelet/core/backend_config.dart';
import 'package:tracelet/domain/auth/api_auth_context.dart';
import 'package:tracelet/domain/auth/auth_required_exception.dart';

class TraceletApiException implements Exception {
  TraceletApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'TraceletApiException($statusCode): $message';
}

class TraceletApiClient {
  TraceletApiClient({
    required ApiAuthContext auth,
    http.Client? httpClient,
    String? baseUrl,
  })  : _auth = auth,
        _http = httpClient ?? http.Client(),
        _baseUrl =
            (baseUrl ?? BackendConfig.httpApiUrl).replaceAll(RegExp(r'/+$'), '');

  final ApiAuthContext _auth;
  final http.Client _http;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _http.put(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<void> delete(String path, [Map<String, dynamic>? body]) async {
    final response = await _http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    if (response.statusCode == 401) {
      throw AuthRequiredException('Session expired');
    }
    if (response.statusCode >= 400) {
      throw TraceletApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _auth.bearerToken();
    final userId = _auth.userId;

    if ((token == null || token.isEmpty) &&
        (userId == null || userId.isEmpty)) {
      throw AuthRequiredException();
    }

    final headers = <String, String>{
      'content-type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }

    if (userId != null && userId.isNotEmpty) {
      headers['x-user-id'] = userId;
    }

    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    if (response.statusCode == 401) {
      throw AuthRequiredException(
        body['message']?.toString() ?? 'Session expired',
      );
    }

    if (response.statusCode >= 400) {
      throw TraceletApiException(
        body['message']?.toString() ?? _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    if (body.containsKey('message') &&
        body.length == 1 &&
        response.statusCode != 200) {
      throw TraceletApiException(
        body['message'].toString(),
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  String _errorMessage(http.Response response) =>
      'HTTP ${response.statusCode}: ${response.body}';
}
