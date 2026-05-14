import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/api_config.dart';

/// Client HTTP centralisé pour toutes les appels API
/// Utilise Dio avec intercepteurs pour authentification et logging
class BaseClient {
  /// Base API (suffixe /api/v1/). Les chemins passés à Dio sont relatifs, ex. `accounts/login/`.
  static String get _baseUrl => ApiConfig.baseUrl;
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  /// Hôte et port du serveur (ex. `192.168.1.73:8000`) pour WebSockets `ws://…`.
  static String get apiHostAndPort => ApiConfig.wsHost;

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  /// Singleton pattern
  static final BaseClient _instance = BaseClient._internal();
  factory BaseClient() => _instance;
  BaseClient._internal() {
    _initializeDio();
  }

  /// Set the callback for token expiration
  void setOnTokenExpiredCallback(Function()? callback) {
    // Remove existing auth interceptor and add new one with callback
    _dio.interceptors
        .removeWhere((interceptor) => interceptor is _AuthInterceptor);
    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _logger, _dio,
        onTokenExpired: callback));
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Ajout des intercepteurs
    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _logger, _dio));
    _dio.interceptors.add(_LoggingInterceptor(_logger));
  }

  /// Méthode GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode DELETE
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Méthode PATCH
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Gestion centralisée des erreurs Dio
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Délai de connexion dépassé. Vérifiez votre connexion internet.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(
          error.response?.statusCode ?? 0,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Requête annulée',
          type: ApiErrorType.cancelled,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Impossible de se connecter au serveur. Vérifiez votre connexion.',
          type: ApiErrorType.network,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Erreur de certificat SSL',
          type: ApiErrorType.certificate,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: 'Une erreur inattendue est survenue',
          type: ApiErrorType.unknown,
        );
    }
  }

  /// Gestion des codes d'erreur HTTP
  ApiException _handleHttpError(int statusCode, dynamic responseData) {
    String message = 'Erreur serveur';

    // Extraire le message d'erreur de la réponse si disponible
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? responseData['error'] ?? message;
    } else if (responseData is String) {
      message = responseData;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message.isEmpty ? 'Requête invalide' : message,
          type: ApiErrorType.badRequest,
        );

      case 401:
        return ApiException(
          message: 'Session expirée. Veuillez vous reconnecter.',
          type: ApiErrorType.unauthorized,
          shouldLogout: true,
        );

      case 403:
        return ApiException(
          message: 'Accès refusé. Permissions insuffisantes.',
          type: ApiErrorType.forbidden,
        );

      case 404:
        return ApiException(
          message: 'Ressource non trouvée',
          type: ApiErrorType.notFound,
        );

      case 422:
        return ApiException(
          message: message.isEmpty ? 'Données invalides' : message,
          type: ApiErrorType.validation,
        );

      case 429:
        return ApiException(
          message: 'Trop de requêtes. Veuillez réessayer plus tard.',
          type: ApiErrorType.tooManyRequests,
        );

      case 500:
        return ApiException(
          message: 'Erreur interne du serveur',
          type: ApiErrorType.serverError,
        );

      case 502:
      case 503:
      case 504:
        return ApiException(
          message: 'Service temporairement indisponible',
          type: ApiErrorType.serviceUnavailable,
        );

      default:
        return ApiException(
          message: message.isEmpty ? 'Erreur HTTP $statusCode' : message,
          type: ApiErrorType.unknown,
        );
    }
  }

  /// Getter pour accéder à l'instance Dio directement si besoin
  Dio get dio => _dio;
}

/// Intercepteur pour ajouter le token JWT aux requêtes
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;
  final Dio _dio; // Ajout de l'instance Dio
  final Function()? onTokenExpired;
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  bool _isRefreshing = false;

  _AuthInterceptor(this._secureStorage, this._logger, this._dio,
      {this.onTokenExpired});

  bool _isPublicPath(String path) {
    return path.contains('accounts/login/') ||
        path.contains('accounts/register/') ||
        path.contains('accounts/forgot-password/') ||
        path.contains('accounts/google-auth/') ||
        path.contains('accounts/token/refresh/');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_isPublicPath(err.requestOptions.path)) {
<<<<<<< HEAD
      final responseData = err.response?.data;

      // Éviter les boucles infinies de refresh
      if (_isRefreshing) {
        _logger.w('Refresh déjà en cours, suppression des tokens');
        await _clearTokens();
        onTokenExpired?.call();
        handler.next(err);
        return;
      }

      _isRefreshing = true;

      try {
        // Tenter de rafraîchir le token
        final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResponse = await _dio.post(
            'accounts/token/refresh/',
            data: {'refresh': refreshToken},
            options: Options(
              headers: {'Content-Type': 'application/json'},
            ),
          );

          if (refreshResponse.statusCode == 200) {
            final newAccessToken = refreshResponse.data['access'] as String?;

            if (newAccessToken != null) {
              // Sauvegarder le nouveau token
              await _secureStorage.write(key: _tokenKey, value: newAccessToken);
              _logger.i('✅ Token rafraîchi avec succès');

              // Retenter la requête originale avec le nouveau token
              final originalOptions = err.requestOptions;
              originalOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';

              try {
                final retryResponse = await _dio.fetch(originalOptions);
                _isRefreshing = false;
                handler.resolve(retryResponse);
                return;
              } catch (retryError) {
                _logger.e('Échec de la retry: ${retryError.toString()}');
              }
            }
=======
      // Tenter de rafraîchir le token pour toute erreur 401
      _logger.w('401 reçu — tentative de rafraîchissement du token JWT');
      final refreshed = await _tryRefreshToken();

      if (refreshed) {
        // Réessayer la requête originale avec le nouveau token
        final newToken = await _secureStorage.read(key: _tokenKey);
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          try {
            final response = await _dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            _logger.e('Échec de la réessai après rafraîchissement: $e');
>>>>>>> baf250f (mmisse a jour ddu gradle)
          }
        }

<<<<<<< HEAD
        // Si le refresh a échoué, nettoyer les tokens
        _logger
            .w('JWT expiré et refresh échoué : suppression du stockage token');
        await _clearTokens();
        onTokenExpired?.call();
      } catch (refreshError) {
        _logger.e('Erreur lors du refresh: ${refreshError.toString()}');
        await _clearTokens();
        onTokenExpired?.call();
      } finally {
        _isRefreshing = false;
      }
=======
      // Si le rafraîchissement échoue
      _logger.w('JWT expiré ou invalide : suppression du stockage token');
      await _secureStorage.delete(key: _tokenKey);
>>>>>>> baf250f (mmisse a jour ddu gradle)
    }

    handler.next(err);
  }

<<<<<<< HEAD
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: 'user_data');
=======
  /// Tente de rafraîchir le token JWT
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'jwt_refresh_token');
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        'accounts/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await _secureStorage.write(key: _tokenKey, value: newAccessToken);
        _logger.i('Token JWT rafraîchi avec succès');
        return true;
      }
    } catch (e) {
      _logger.e('Échec du rafraîchissement du token: $e');
    }
    return false;
>>>>>>> baf250f (mmisse a jour ddu gradle)
  }
}

/// Intercepteur pour le logging des requêtes/réponses
class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('🚀 [${options.method}] ${options.uri}');
    if (options.data != null) {
      _logger.d('📤 Request Data: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      _logger.d('📤 Query Params: ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('✅ [${response.statusCode}] ${response.requestOptions.uri}');
    _logger.d('📥 Response Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '❌ [${err.response?.statusCode ?? 'ERROR'}] ${err.requestOptions.uri}',
    );
    _logger.e('📥 Error Response: ${err.response?.data}');
    _logger.e('📥 Error Message: ${err.message}');
    handler.next(err);
  }
}

/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final bool shouldLogout;

  ApiException({
    required this.message,
    required this.type,
    this.shouldLogout = false,
  });

  @override
  String toString() => message;
}

/// Types d'erreurs API
enum ApiErrorType {
  timeout,
  network,
  certificate,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  tooManyRequests,
  serverError,
  serviceUnavailable,
  cancelled,
  unknown,
}
