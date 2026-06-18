import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';

class AuthSessionStore {
  const AuthSessionStore();

  static const _tokenKey = 'komi_access_token';
  static const _userKey = 'komi_user';
  static const _expiresAtKey = 'komi_session_expires_at';
  static const _sessionDuration = Duration(days: 30);

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_userKey, jsonEncode(session.user.toJson()));
    await prefs.setString(
      _expiresAtKey,
      DateTime.now().add(_sessionDuration).toIso8601String(),
    );
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<KomiUser?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    if (rawUser == null) return null;

    final decoded = jsonDecode(rawUser);
    if (decoded is! Map<String, dynamic>) return null;
    return KomiUser.fromJson(decoded);
  }

  Future<void> updateUser(KomiUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final rawExpiresAt = prefs.getString(_expiresAtKey);

    if (token == null || token.isEmpty || rawExpiresAt == null) {
      return false;
    }

    final expiresAt = DateTime.tryParse(rawExpiresAt);
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      await clear();
      return false;
    }

    return true;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_expiresAtKey);
  }
}
