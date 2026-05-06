import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApiClient {
  AuthApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'KOMI_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final http.Client _httpClient;
  final String baseUrl;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _postAuth(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _postAuth(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthSession> _postAuth(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _httpClient.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(
          _extractErrorMessage(data),
          statusCode: response.statusCode,
        );
      }

      return AuthSession.fromJson(data);
    } on AuthApiException {
      rethrow;
    } catch (_) {
      throw const AuthApiException(
        'Impossible de joindre le serveur Komi. Verifie que l API est lancee.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return const {};

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    return 'Une erreur est survenue.';
  }
}
