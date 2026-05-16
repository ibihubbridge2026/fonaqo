import 'package:flutter/foundation.dart';

/// Stub no-op du service de monitoring d'erreurs.
/// Sentry a été retiré du projet (incompatibilité Kotlin 1.6).
/// Toutes les méthodes loggent en debug uniquement.
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance =
      ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  Future<void> init({required String dsn}) async {
    debugPrint('[ErrorMonitoring] init() (stub no-op)');
  }

  Future<String?> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('🚨 [ErrorMonitoring] captureException: $exception');
    if (stackTrace != null) debugPrint(stackTrace.toString());
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
    debugPrint('[ErrorMonitoring][breadcrumb][${category ?? "default"}] $message');
  }
}
