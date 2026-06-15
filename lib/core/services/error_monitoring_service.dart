import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Monitoring d'erreurs : stub local + capture globale.
/// Sentry côté Flutter reste optionnel (incompatibilité Kotlin historique) ;
/// le backend Django utilise `SENTRY_DSN` dans `.env`.
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance =
      ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  bool _initialized = false;
  String? _dsn;

  Future<void> init({String? dsn}) async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env absent en prod CI — acceptable
    }

    _dsn = dsn ??
        dotenv.env['SENTRY_DSN'] ??
        const String.fromEnvironment('SENTRY_DSN');
    if (_dsn != null && _dsn!.isEmpty) _dsn = null;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        captureException(
          details.exception,
          stackTrace: details.stack,
          message: details.context?.toDescription(),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(captureException(error, stackTrace: stack));
      return true;
    };

    _initialized = true;
    debugPrint(
      '[ErrorMonitoring] init() — DSN ${_dsn != null ? "configuré (backend)" : "non configuré"}',
    );
  }

  Future<String?> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('🚨 [ErrorMonitoring] ${message ?? "captureException"}: $exception');
    if (stackTrace != null) debugPrint(stackTrace.toString());
    if (context != null && context.isNotEmpty) {
      debugPrint('[ErrorMonitoring] context: $context');
    }
    return null;
  }

  Future<void> setUserContext({
    required String userId,
    String? email,
    String? username,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('[ErrorMonitoring] setUserContext: $userId');
  }

  Future<void> clearUserContext() async {
    debugPrint('[ErrorMonitoring] clearUserContext');
  }

  Future<String?> captureMessage(String message,
      {String level = 'info'}) async {
    debugPrint('[ErrorMonitoring][$level] $message');
    return null;
  }

  Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    debugPrint(
        '[ErrorMonitoring][breadcrumb][${category ?? "default"}] $message');
  }
}
