import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/api_config.dart';
import '../utils/retry_utils.dart';

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
    _dio.interceptors.add(RetryUtils.createRetryInterceptor(logger: _logger));
  }

  /// Méthode GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onReceiveProgress,
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
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
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
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
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
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
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
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        return _handleHttpError(statusCode ?? 0, responseData);

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
  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  bool _isRefreshing = false;

  _AuthInterceptor(
    this._secureStorage,
    this._logger,
    this._dio, {
    this.onTokenExpired,
  });

  /// Vérifie si le chemin est public (ne nécessite pas d'authentification)
  bool _isPublicPath(String path) {
    final publicPaths = [
      'accounts/login/',
      'accounts/register/',
      'accounts/refresh/',
      'accounts/logout/',
      'accounts/forgot-password/',
      'accounts/google-auth/',
      'accounts/token/refresh/',
    ];

    return publicPaths.any((publicPath) => path.contains(publicPath));
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
    // FILTRAGE STRICT : Seules les vraies erreurs 401 déclenchent la déconnexion
    final isExact401 = err.response?.statusCode == 401;
    final isNotPublicPath = !_isPublicPath(err.requestOptions.path);
    final hasResponse = err.response != null;

    _logger.d(
        '🔍 Analyse erreur: statusCode=${err.response?.statusCode}, isPublicPath=${_isPublicPath(err.requestOptions.path)}');

    if (isExact401 && isNotPublicPath && hasResponse) {
      // Log détaillé pour debug des erreurs 401
      _logger.e('🔴 VRAIE ERREUR 401 DÉTECTÉE:');
      _logger.e('📍 URL: ${err.requestOptions.uri}');
      _logger.e('📍 Méthode: ${err.requestOptions.method}');
      _logger.e('📍 Headers: ${err.requestOptions.headers}');
      _logger.e('📍 Corps de l\'erreur: ${err.response?.data}');
      _logger.e('📍 Message: ${err.message}');

      // Tenter de rafraîchir le token pour toute erreur 401
      _logger.w('🔄 401 reçu — tentative de rafraîchissement du token JWT');
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
          }
        }
      }

      // Si le rafraîchissement échoue, SEULEMENT là on déconnecte
      _logger.w('🚨 JWT expiré ou invalide : DÉCONNEXION confirmée');
      _logger.w('📍 Suppression du stockage token et appel de onTokenExpired');
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: 'user_data');
      onTokenExpired?.call();
      return; // Important : ne pas appeler handler.next(err) après déconnexion
    }

    // Pour toutes les autres erreurs (404, 500, réseau, etc.), on ne fait rien de spécial
    if (err.response?.statusCode != null) {
      _logger.d(
          'ℹ️ Erreur ${err.response?.statusCode} gérée normalement: ${err.requestOptions.uri}');
    } else {
      _logger.d('ℹ️ Erreur réseau/générale: ${err.type} - ${err.message}');
    }

    handler.next(err);
  }

  /// Tente de rafraîchir le token JWT
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'jwt_refresh_token');
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'No-Auth': 'True'
        }, // Évite l'interception par l'auth interceptor
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
    // Catégoriser et logger les erreurs de manière plus intelligente
    switch (err.type) {
      case DioExceptionType.connectionError:
        _logger.w('🔌 Connexion refusée: ${err.requestOptions.uri.host}');
        break;
      case DioExceptionType.connectionTimeout:
        _logger.w('⏱️ Timeout de connexion: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.receiveTimeout:
        _logger.w('⏱️ Timeout de réception: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.sendTimeout:
        _logger.w('⏱️ Timeout d\'envoi: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.badResponse:
        _logger.e('❌ [${err.response?.statusCode}] ${err.requestOptions.uri}');
        if (err.response?.data != null) {
          _logger.d('📥 Response Data: ${err.response?.data}');
        }
        break;
      case DioExceptionType.cancel:
        _logger.d('🚫 Requête annulée: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.badCertificate:
        _logger.e('� Erreur SSL: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.unknown:
        _logger.e('❌ Erreur inconnue: ${err.message}');
        break;
    }

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
