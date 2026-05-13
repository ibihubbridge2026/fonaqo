import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Client HTTP centralisé pour toutes les appels API
/// Utilise Dio avec intercepteurs pour authentification et logging
class BaseClient {
  /// Base API (suffixe /api/v1/). Les chemins passés à Dio sont relatifs, ex. `accounts/login/`.
  /// Émulateur Android : http://10.0.2.2:8000/api/v1/
  static const String _baseUrl = 'http://192.168.1.73:8000/api/v1/';
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  /// Hôte et port du serveur (ex. `192.168.1.73:8000`) pour WebSockets `ws://…`.
  static String get apiHostAndPort {
    final u = Uri.parse(_baseUrl);
    if (u.hasPort) {
      return '${u.host}:${u.port}';
    }
    return u.host;
  }

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

  _AuthInterceptor(this._secureStorage, this._logger, this._dio,
      {this.onTokenExpired});

  bool _isPublicPath(String path) {
    return path.contains('accounts/login/') ||
        path.contains('accounts/register/') ||
        path.contains('accounts/forgot-password/') ||
        path.contains('accounts/google-auth/');
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final responseData = err.response?.data;

      // Token expiré ou invalide - nettoyer et rediriger vers login
      _logger.w('JWT expiré ou invalide : suppression du stockage token');
      _secureStorage.delete(key: _tokenKey);
      _secureStorage.delete(key: 'user_data');

      // Notifier l'application pour rediriger vers l'écran de login
      onTokenExpired?.call();
    }
    handler.next(err);
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
