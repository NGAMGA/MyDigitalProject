import 'package:dio/dio.dart';

class TranslationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mymemory.translated.net',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));


  static const String sourceLang = 'en';

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'de': 'Deutsch',
    'pt': 'Português',
    'ar': 'العربية',
  };

  Future<String> translate(String text, String targetLang) async {

    if (targetLang == sourceLang) return text;

    try {
      final chunks = _splitText(text, 480);
      final translated = <String>[];

      for (final chunk in chunks) {
        final response = await _dio.get(
          '/get',
          queryParameters: {
            'q': chunk,
            'langpair': '$sourceLang|$targetLang',
          },
        );
        final result =
        response.data['responseData']['translatedText'] as String;
        translated.add(result);
      }

      return translated.join(' ');
    } catch (e) {
      throw 'Traduction impossible. Verifiez votre connexion.';
    }
  }

  List<String> _splitText(String text, int maxLength) {
    final words = text.split(' ');
    final chunks = <String>[];
    var current = '';

    for (final word in words) {
      if ((current + ' ' + word).length > maxLength) {
        if (current.isNotEmpty) chunks.add(current.trim());
        current = word;
      } else {
        current += ' $word';
      }
    }
    if (current.trim().isNotEmpty) chunks.add(current.trim());
    return chunks;
  }
}