import 'package:dio/dio.dart';

class TranslationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mymemory.translated.net',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'fr': 'Francais',
    'es': 'Espanol',
    'it': 'Italiano',
    'de': 'Deutsch',
    'pt': 'Portugues',
  };

  final Map<String, String> _cache = {};

  Future<String> translate(String text, String targetLang) async {
    if (targetLang == 'en') return text;

    final cacheKey = '$targetLang:${text.hashCode}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {

      final chunks = _splitText(text, 480);
      final translated = <String>[];

      for (final chunk in chunks) {
        final response = await _dio.get(
          '/get',
          queryParameters: {
            'q': chunk,
            'langpair': 'en|$targetLang',
          },
        );
        final result =
            response.data['responseData']['translatedText'] as String?;
        if (result == null || result.trim().isEmpty) {
          throw Exception('Empty translation');
        }
        translated.add(_decodeHtmlEntities(result));
      }

      final finalText = translated.join(' ');
      _cache[cacheKey] = finalText;
      return finalText;
    } catch (e) {
      throw 'Traduction impossible. Verifiez votre connexion puis reessayez.';
    }
  }

  List<String> _splitText(String text, int maxLength) {
    final words = text.split(' ');
    final chunks = <String>[];
    var current = '';

    for (final word in words) {
      if ('$current $word'.length > maxLength) {
        if (current.isNotEmpty) chunks.add(current.trim());
        current = word;
      } else {
        current += ' $word';
      }
    }
    if (current.trim().isNotEmpty) chunks.add(current.trim());
    return chunks;
  }

  String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
