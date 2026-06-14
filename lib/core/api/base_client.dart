import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../config/api_config.dart';
import '../services/memory_auth_cache.dart';
import '../utils/retry_utils.dart';
import 'token_refresh_result.dart';

/// Client HTTP centralisé pour toutes les appels API
/// Utilise Dio avec intercepteurs pour authentification et logging
class BaseClient {
  /// Base API (suffixe /api/v1/). Les chemins passés à Dio sont relatifs, ex. `accounts/login/`.
  static String get _baseUrl => ApiConfig.baseUrl;
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 30);

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
        sendTimeout: _sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Ajout des intercepteurs
    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _logger, _dio));
    // LoggingInterceptor désactivé en production pour améliorer les performances
    // Commenter la ligne suivante pour activer en développement
    // _dio.interceptors.add(_LoggingInterceptor(_logger));
    _dio.interceptors
        .add(RetryUtils.createRetryInterceptor(logger: _logger, dio: _dio));
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

      case 409:
        return ApiException(
          message: message.isEmpty
              ? 'Conflit : ressource déjà modifiée'
              : message,
          type: ApiErrorType.conflict,
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

  /// Détecte une erreur réseau (hors expiration de session).
  static bool isNetworkErrorPublic(DioException err) =>
      _AuthInterceptor.isNetworkError(err);
}

/// Intercepteur pour ajouter le token JWT aux requêtes
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;
  final Dio _dio; // Ajout de l'instance Dio
  final Function()? onTokenExpired;
  final MemoryAuthCache _memoryCache;
  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  _AuthInterceptor(
    this._secureStorage,
    this._logger,
    this._dio, {
    this.onTokenExpired,
  }) : _memoryCache = MemoryAuthCache();

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
      _logger.d('🔓 Chemin public, skip auth: ${options.path}');
      handler.next(options);
      return;
    }

    // Hydrater depuis SecureStorage si la mémoire est vide (évite les 401 intempestifs).
    await _memoryCache.ensureLoaded();
    final token = _memoryCache.accessToken;
    _logger.d(
        '🔑 Token lu: ${token != null ? "Présent (${token.length} chars)" : "ABSENT"} pour ${options.path}');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _logger.d('✅ Header Authorization ajouté');
    } else {
      _logger.w('⚠️ Token absent après hydratation pour ${options.path}');
    }
    handler.next(options);
  }

  static bool isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.error is SocketException;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Panne réseau : conserver la session, propager l'erreur sans déconnexion.
    if (isNetworkError(err)) {
      _logger.d(
          '📴 Erreur réseau sur ${err.requestOptions.path} — session conservée');
      return handler.next(err);
    }

    final isExact401 = err.response?.statusCode == 401;
    final isNotPublicPath = !_isPublicPath(err.requestOptions.path);
    final hasResponse = err.response != null;

    _logger.d(
        '🔍 Analyse erreur: statusCode=${err.response?.statusCode}, isPublicPath=${_isPublicPath(err.requestOptions.path)}');

    if (isExact401 && isNotPublicPath && hasResponse) {
      // Protection contre les boucles de refresh infinies
      final refreshAttempt =
          err.requestOptions.extra['refresh_attempt'] as int? ?? 0;
      if (refreshAttempt >= 1) {
        _logger.w('🚨 Refresh déjà tenté pour cette requête — rejet sans déconnexion');
        return handler.reject(err);
      }
      err.requestOptions.extra['refresh_attempt'] = refreshAttempt + 1;

      // Log détaillé pour debug des erreurs 401
      _logger.e('🔴 VRAIE ERREUR 401 DÉTECTÉE:');
      _logger.e('📍 URL: ${err.requestOptions.uri}');
      _logger.e('📍 Méthode: ${err.requestOptions.method}');
      _logger.e('📍 Headers: ${err.requestOptions.headers}');
      _logger.e('📍 Corps de l\'erreur: ${err.response?.data}');
      _logger.e('📍 Message: ${err.message}');

      // MUTEX REFRESH: Si déjà en cours de refresh, attendre
      if (_isRefreshing) {
        _logger.w('⏳ Refresh déjà en cours, attente...');
        if (_refreshCompleter != null) {
          await _refreshCompleter!.future;

          // Une fois le refresh terminé, réessayer avec le nouveau token
          final newToken = _memoryCache.accessToken;
          if (newToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await _dio.fetch(err.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              _logger.e('Échec de la réessai après refresh: $e');
            }
          }
        }
      } else {
        // Premier 401: lancer le refresh
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();

        _logger.w('🔄 401 reçu — tentative de rafraîchissement du token JWT');
        final refreshResult = await _tryRefreshToken();

        // Notifier tous les requêtes en attente
        _refreshCompleter!.complete();
        _isRefreshing = false;
        _refreshCompleter = null;

        if (refreshResult == TokenRefreshResult.sessionRevoked) {
          _logger.e('🚨 Refresh token révoqué/expiré — déconnexion requise');
          onTokenExpired?.call();
          return handler.reject(err);
        }

        if (refreshResult == TokenRefreshResult.networkError) {
          _logger.w(
              '📴 Refresh impossible (réseau) — requête rejetée, session conservée');
          return handler.reject(err);
        }

        if (refreshResult == TokenRefreshResult.success) {
          final newToken = _memoryCache.accessToken;
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
      }

      _logger.w('⚠️ Refresh échoué — requête rejetée, session conservée');
      return handler.reject(err);
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

  /// Tente de rafraîchir le token JWT.
  Future<TokenRefreshResult> _tryRefreshToken() async {
    try {
      await _memoryCache.ensureLoaded();
      final refreshToken = _memoryCache.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('Refresh token absent après hydratation');
        return TokenRefreshResult.sessionRevoked;
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'No-Auth': 'True'},
      ));

      final response = await dio.post(
        'accounts/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String?;
        if (newAccessToken == null || newAccessToken.isEmpty) {
          _logger.e('Access token absent dans la réponse de refresh');
          return TokenRefreshResult.failed;
        }
        final cleanToken = newAccessToken
            .trim()
            .replaceAll('#', '')
            .replaceAll(RegExp(r'\s'), '');
        await _memoryCache.updateAccessToken(cleanToken);
        _logger.i('Token JWT rafraîchi avec succès');
        return TokenRefreshResult.success;
      }

      if (response.statusCode == 401) {
        return TokenRefreshResult.sessionRevoked;
      }
      return TokenRefreshResult.failed;
    } on DioException catch (e) {
      if (isNetworkError(e)) {
        _logger.w('Refresh token — panne réseau: ${e.type}');
        return TokenRefreshResult.networkError;
      }
      if (e.response?.statusCode == 401) {
        _logger.e('Refresh token rejeté par le serveur (401)');
        return TokenRefreshResult.sessionRevoked;
      }
      _logger.e('Échec du rafraîchissement du token: $e');
      return TokenRefreshResult.failed;
    } catch (e) {
      _logger.e('Échec du rafraîchissement du token: $e');
      return TokenRefreshResult.failed;
    }
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
  conflict,
  validation,
  tooManyRequests,
  serverError,
  serviceUnavailable,
  cancelled,
  unknown,
}
