import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Utilitaire de retry réseau
class RetryUtils {
  static const int defaultMaxRetries = 3;

  static const Duration defaultBaseDelay =
      Duration(seconds: 1);

  static const double defaultBackoffMultiplier = 2.0;

  /// Exécute une opération avec retry automatique
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier =
        defaultBackoffMultiplier,
    Logger? logger,
    String? operationName,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        logger?.d(
          '🔄 Tentative ${attempts + 1}/$maxRetries '
          '${operationName ?? ''}',
        );

        final result = await operation();

        if (attempts > 0) {
          logger?.i(
            '✅ Succès après ${attempts + 1} tentatives',
          );
        }

        return result;
      } catch (e) {
        attempts++;

        final isRetryable =
            _isRetryableError(e);

        if (!isRetryable) {
          logger?.e(
            '❌ Erreur non retryable: $e',
          );

          rethrow;
        }

        if (attempts >= maxRetries) {
          logger?.e(
            '❌ Échec après $maxRetries tentatives',
          );

          rethrow;
        }

        final delay = calculateRetryDelay(
          attempts,
          baseDelay: baseDelay,
          multiplier: backoffMultiplier,
        );

        logger?.w(
          '⏱️ Retry dans '
          '${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);
      }
    }

    throw Exception(
      'Échec après $maxRetries tentatives',
    );
  }

  /// Vérifie si l'erreur peut être retry
  static bool _isRetryableError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;

        case DioExceptionType.badResponse:
          return isRetryableStatusCode(
            error.response?.statusCode,
          );

        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          return false;
      }
    }

    if (error is SocketException) {
      return true;
    }

    if (error is HttpException) {
      return true;
    }

    final message = error.toString().toLowerCase();

    return message.contains('timeout') ||
        message.contains('connection refused') ||
        message.contains('network');
  }

  /// Vérifie si le status code est retryable
  static bool isRetryableStatusCode(
    int? statusCode,
  ) {
    if (statusCode == null) {
      return false;
    }

    return (statusCode >= 500 &&
            statusCode < 600) ||
        statusCode == 429;
  }

  /// Calcule le délai exponentiel
  static Duration calculateRetryDelay(
    int attempt, {
    Duration baseDelay = defaultBaseDelay,
    double multiplier =
        defaultBackoffMultiplier,
    Duration? maxDelay,
  }) {
    final milliseconds =
        (baseDelay.inMilliseconds *
                (multiplier * attempt))
            .round();

    final delay =
        Duration(milliseconds: milliseconds);

    if (maxDelay != null &&
        delay > maxDelay) {
      return maxDelay;
    }

    return delay;
  }

  /// Crée un interceptor Dio avec retry
  static Interceptor createRetryInterceptor({
    int maxRetries = defaultMaxRetries,
    Duration baseDelay = defaultBaseDelay,
    double backoffMultiplier =
        defaultBackoffMultiplier,
    Logger? logger,
  }) {
    return RetryInterceptor(
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      backoffMultiplier:
          backoffMultiplier,
      logger: logger,
    );
  }
}

/// Interceptor Dio pour retry automatique
class RetryInterceptor extends Interceptor {
  final int maxRetries;

  final Duration baseDelay;

  final double backoffMultiplier;

  final Logger? logger;

  RetryInterceptor({
    this.maxRetries =
        RetryUtils.defaultMaxRetries,
    this.baseDelay =
        RetryUtils.defaultBaseDelay,
    this.backoffMultiplier =
        RetryUtils.defaultBackoffMultiplier,
    this.logger,
  });

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions =
        err.requestOptions;

    final retryCount =
        requestOptions.extra['retryCount']
            as int? ??
            0;

    if (!_isRetryableError(err) ||
        retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    requestOptions.extra['retryCount'] =
        retryCount + 1;

    final delay =
        RetryUtils.calculateRetryDelay(
      retryCount + 1,
      baseDelay: baseDelay,
      multiplier: backoffMultiplier,
    );

    logger?.w(
      '🔄 Retry ${retryCount + 1}/$maxRetries '
      '→ ${requestOptions.uri}',
    );

    await Future.delayed(delay);

    try {
      final dio = Dio();

      final response = await dio.fetch(
        requestOptions,
      );

      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isRetryableError(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        return RetryUtils
            .isRetryableStatusCode(
          error.response?.statusCode,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return false;
    }
  }
}

/// Extension Dio avec retry
extension DioRetryExtension on Dio {
  Future<Response<T>> executeWithRetry<T>(
    RequestOptions options, {
    int maxRetries =
        RetryUtils.defaultMaxRetries,
    Duration baseDelay =
        RetryUtils.defaultBaseDelay,
    double backoffMultiplier =
        RetryUtils.defaultBackoffMultiplier,
    Logger? logger,
  }) {
    return RetryUtils.executeWithRetry(
      () => fetch<T>(options),
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      backoffMultiplier:
          backoffMultiplier,
      logger: logger,
      operationName:
          'HTTP ${options.method} ${options.path}',
    );
  }
}