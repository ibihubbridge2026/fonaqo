import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configuration et initialisation de Sentry pour le monitoring d'erreurs
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance = ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  /// Initialisation de Sentry - À appeler dans main()
  Future<void> init({required String dsn}) async {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate = 1.0; // 100% des traces pour le dev (à réduire en prod)
          options.profilesSampleRate = 0.5; // 50% des profils
          options.debug = true; // Activer en dev seulement
          
          // Tags globaux pour filtrer les erreurs
          options.addGlobalTag('app_version', '1.0.0');
          options.addGlobalTag('platform', 'mobile');
          
          // Ne pas envoyer les erreurs en mode debug (optionnel)
          // options.environment = 'development';
        },
      );
      
      debugPrint('✅ Sentry initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Échec initialisation Sentry: $e');
    }
  }

  /// Capture une exception avec contexte optionnel
  Future<SentryId?> captureException(
    Object exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (context != null) {
        await Sentry.configureScope((scope) {
          context.forEach((key, value) {
            scope.setContext(key, value);
          });
        });
      }

      final id = await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        message: message != null ? SentryMessage(message) : null,
      );

      debugPrint('🚨 Erreur capturée par Sentry: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Échec capture erreur Sentry: $e');
      return null;
    }
  }

  /// Ajoute un breadcrumb (trace d'événement avant l'erreur)
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) async {
    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: level,
          data: data,
        ),
      );
    } catch (e) {
      debugPrint('❌ Échec ajout breadcrumb: $e');
    }
  }

  /// Configure le contexte utilisateur pour le debugging
  Future<void> setUserContext({
    required String userId,
    String? email,
    String? username,
    Map<String, dynamic>? data,
  }) async {
    try {
      await Sentry.configureScope((scope) {
        scope.user = SentryUser(
          id: userId,
          email: email,
          username: username,
          data: data,
        );
      });
      debugPrint('👤 Contexte utilisateur Sentry configuré pour: $userId');
    } catch (e) {
      debugPrint('❌ Échec configuration utilisateur Sentry: $e');
    }
  }

  /// Efface le contexte utilisateur (au logout)
  Future<void> clearUserContext() async {
    try {
      await Sentry.configureScope((scope) {
        scope.user = null;
      });
      debugPrint('🧹 Contexte utilisateur Sentry effacé');
    } catch (e) {
      debugPrint('❌ Échec effacement contexte utilisateur: $e');
    }
  }

  /// Capture un message d'information
  Future<SentryId?> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    try {
      return await Sentry.captureMessage(message, level: level);
    } catch (e) {
      debugPrint('❌ Échec capture message: $e');
      return null;
    }
  }

  /// Démarre une transaction pour le performance monitoring
  ISentrySpan? startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    try {
      final transaction = Sentry.startTransaction(
        name,
        operation,
        description: description,
      );
      return transaction;
    } catch (e) {
      debugPrint('❌ Échec démarrage transaction: $e');
      return null;
    }
  }
}
