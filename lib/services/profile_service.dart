import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_models.dart';
import '../features/auth/data/auth_session_store.dart';

class ProfileServiceException implements Exception {
  const ProfileServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileService {
  ProfileService({
    http.Client? httpClient,
    AuthSessionStore? sessionStore,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _sessionStore = sessionStore ?? const AuthSessionStore(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'KOMI_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final http.Client _httpClient;
  final AuthSessionStore _sessionStore;
  final String baseUrl;

  Future<KomiUser> getMe() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ProfileServiceException('Session expiree.');
    }
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProfileServiceException(_extractErrorMessage(data));
      }
      final user = KomiUser.fromJson(data);
      await _sessionStore.updateUser(user);
      return user;
    } on ProfileServiceException {
      rethrow;
    } catch (_) {
      throw const ProfileServiceException(
        'Impossible de joindre le serveur Komi.',
      );
    }
  }

  Future<KomiUser> updateMe(Map<String, dynamic> fields) async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ProfileServiceException(
        'Session expiree. Reconnecte-toi pour modifier ton profil.',
      );
    }

    try {
      final response = await _httpClient.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(fields),
      );

      final data = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ProfileServiceException(_extractErrorMessage(data));
      }

      final user = KomiUser.fromJson(data);
      await _sessionStore.updateUser(user);
      return user;
    } on ProfileServiceException {
      rethrow;
    } catch (_) {
      throw const ProfileServiceException(
        'Impossible de joindre le serveur Komi.',
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
    return 'Impossible de mettre a jour le profil.';
  }
}
