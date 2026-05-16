import 'package:dio/dio.dart';
import '../api/base_client.dart';

/// Wrapper léger sur [BaseClient] pour exposer une API simple
/// (`get`, `post`, `put`, `delete`) qui retourne directement le `data` décodé.
///
/// Utilisé par les providers (AiSearchProvider, OpportunityProvider, ...).
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final BaseClient _client = BaseClient();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response res =
        await _client.get(path, queryParameters: queryParameters);
    return res.data;
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response res = await _client.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return res.data;
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response res = await _client.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return res.data;
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response res = await _client.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return res.data;
  }
}
