import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_session_store.dart';
import '../models/shopping_product.dart';

class ShoppingListSnapshot {
  const ShoppingListSnapshot({
    required this.id,
    required this.name,
    required this.isActive,
    required this.items,
  });

  factory ShoppingListSnapshot.fromJson(Map<String, dynamic> json) {
    return ShoppingListSnapshot(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Liste de courses actuelle',
      isActive: json['isActive'] as bool? ?? false,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ShoppingProduct.fromJson)
          .toList(),
    );
  }

  final int id;
  final String name;
  final bool isActive;
  final List<ShoppingProduct> items;
}

class ShoppingListService {
  ShoppingListService({
    http.Client? httpClient,
    AuthSessionStore? sessionStore,
  })  : _httpClient = httpClient ?? http.Client(),
        _sessionStore = sessionStore ?? const AuthSessionStore();

  static const _baseUrl = String.fromEnvironment(
    'KOMI_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final http.Client _httpClient;
  final AuthSessionStore _sessionStore;

  Future<ShoppingListSnapshot> loadCurrent() {
    return _request('GET', '/shopping-lists/current');
  }

  Future<ShoppingListSnapshot> replaceItems(List<ShoppingProduct> items) {
    return _request(
      'PUT',
      '/shopping-lists/current/items',
      body: {'items': items.map((item) => item.toJson()).toList()},
    );
  }

  Future<ShoppingListSnapshot> clearCurrent() {
    return _request('DELETE', '/shopping-lists/current');
  }

  Future<ShoppingListSnapshot> createNew({String? name}) {
    return _request(
      'POST',
      '/shopping-lists',
      body: {'name': name ?? 'Liste de courses actuelle'},
    );
  }

  Future<List<ShoppingListSnapshot>> loadHistory() async {
    final token = await _requireToken();
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/shopping-lists/history'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded));
    }
    return (decoded as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ShoppingListSnapshot.fromJson)
        .toList();
  }

  Future<ShoppingListSnapshot> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _requireToken();
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    late http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'POST':
        response =
            await _httpClient.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response =
            await _httpClient.put(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
        break;
      default:
        response = await _httpClient.get(uri, headers: headers);
        break;
    }
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded));
    }
    return ShoppingListSnapshot.fromJson(decoded as Map<String, dynamic>);
  }

  Future<String> _requireToken() async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expiree.');
    }
    return token;
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _message(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return 'Impossible de synchroniser la liste.';
  }
}
