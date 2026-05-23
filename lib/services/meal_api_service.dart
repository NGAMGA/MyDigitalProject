import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';

class MealApiService {
  late final Dio _dio;

  MealApiService() {
    final baseUrl = dotenv.env['API_BASE_URL'] ??
        'https://www.themealdb.com/api/json/v1/1';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }


  Future<List<Meal>> searchMeals(String query) async {
    try {
      final response = await _dio.get('/search.php', queryParameters: {'s': query});
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List).map((j) => Meal.fromSearchJson(j)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  Future<Meal?> getMealDetail(String id) async {
    try {
      final response = await _dio.get('/lookup.php', queryParameters: {'i': id});
      final data = response.data;
      if (data['meals'] == null || (data['meals'] as List).isEmpty) return null;
      return Meal.fromDetailJson(data['meals'][0]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  Future<List<Meal>> getMealsByArea(String area) async {
    try {
      final response = await _dio.get('/filter.php', queryParameters: {'a': area});
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List).map((j) => Meal.fromSearchJson(j)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  Future<List<String>> getAllAreas() async {
    try {
      final response = await _dio.get('/list.php', queryParameters: {'a': 'list'});
      final data = response.data;
      if (data['meals'] == null) return [];
      return (data['meals'] as List)
          .map((j) => j['strArea'].toString())
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Delai de connexion depasse. Verifiez votre reseau.';
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter. Verifiez votre reseau.';
      default:
        return 'Une erreur est survenue. Veuillez reessayer.';
    }
  }
}