import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_session_store.dart';

class SubscriptionPaymentException implements Exception {
  const SubscriptionPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionPaymentService {
  SubscriptionPaymentService({
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

  Future<Uri> createPremiumCheckoutSession() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const SubscriptionPaymentException(
        'Session expiree. Reconnecte-toi pour passer Premium.',
      );
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscription/checkout/premium'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SubscriptionPaymentException(_extractErrorMessage(data));
    }

    final url = data['url'];
    if (url is! String || url.trim().isEmpty) {
      throw const SubscriptionPaymentException(
        'Stripe n a pas renvoye de lien de paiement.',
      );
    }

    return Uri.parse(url);
  }

  Future<void> cancelPremiumSubscription() async {
    await _postSubscriptionAction(
      '/subscription/me/cancel',
      fallbackMessage: 'Impossible de programmer la résiliation.',
    );
  }

  Future<void> resumePremiumSubscription() async {
    await _postSubscriptionAction(
      '/subscription/me/resume',
      fallbackMessage: 'Impossible de réactiver l’abonnement.',
    );
  }

  Future<void> _postSubscriptionAction(
    String path, {
    required String fallbackMessage,
  }) async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const SubscriptionPaymentException(
        'Session expirée. Reconnecte-toi pour gérer ton abonnement.',
      );
    }

    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final data = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SubscriptionPaymentException(
        _extractErrorMessage(data, fallbackMessage: fallbackMessage),
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return const {};

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  String _extractErrorMessage(
    Map<String, dynamic> data, {
    String fallbackMessage = 'Impossible de preparer le paiement Stripe.',
  }) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    return fallbackMessage;
  }
}
