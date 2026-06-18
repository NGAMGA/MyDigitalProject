import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../features/auth/data/auth_session_store.dart';
import '../models/shopping_list_analysis.dart';

class ShoppingListOcrException implements Exception {
  const ShoppingListOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ShoppingListOcrService {
  ShoppingListOcrService({
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

  Future<ShoppingListAnalysisResult> analyzeImage({
    required Uint8List bytes,
    required String filename,
    required String source,
  }) async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ShoppingListOcrException(
        'Session invalide. Merci de te reconnecter.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/shopping-lists/analyze-image'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['source'] = source
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: _mediaTypeFor(filename, bytes),
        ),
      );

    try {
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeResponse(response.bodyBytes);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ShoppingListOcrException(_extractErrorMessage(data));
      }

      return ShoppingListAnalysisResult.fromJson(data);
    } on ShoppingListOcrException {
      rethrow;
    } catch (_) {
      throw const ShoppingListOcrException(
        'Impossible d analyser la photo pour le moment.',
      );
    }
  }

  Future<ShoppingListAnalysisResult> validateItems(List<String> items) async {
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ShoppingListOcrException(
        'Session invalide. Merci de te reconnecter.',
      );
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/shopping-lists/validate-items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'items': items}),
      );
      final data = _decodeResponse(response.bodyBytes);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ShoppingListOcrException(_extractErrorMessage(data));
      }

      return ShoppingListAnalysisResult.fromJson(data);
    } on ShoppingListOcrException {
      rethrow;
    } catch (_) {
      throw const ShoppingListOcrException(
        'Impossible de valider cet item pour le moment.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return const {};

    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return const {};
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }
    return 'Impossible d analyser cette image de liste.';
  }

  MediaType _mediaTypeFor(String filename, Uint8List bytes) {
    final lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.png') || _looksLikePng(bytes)) {
      return MediaType('image', 'png');
    }
    if (lowerName.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  bool _looksLikePng(Uint8List bytes) {
    return bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }
}
