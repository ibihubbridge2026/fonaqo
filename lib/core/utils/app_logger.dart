import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logger configuré pour la production
/// - Debug mode: Logs détaillés avec stack traces
/// - Release mode: Logs limités, aucune information sensible
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;

  AppLogger._internal() {
    _logger = Logger(
      level: kDebugMode ? Level.debug : Level.warning,
      printer: _AppLogPrinter(),
      filter: _AppLogFilter(),
    );
  }

  /// Log debug (uniquement en mode debug)
  void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info (uniquement en mode debug)
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning (tous les modes)
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error (tous les modes, mais sans données sensibles en release)
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) {
      // En release, ne logger que le message sans stack trace ni données sensibles
      _logger.e(_sanitizeMessage(message));
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log verbose (uniquement en mode debug)
  void v(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.v(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log WTF (uniquement en mode debug)
  void wtf(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.wtf(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Nettoie les messages sensibles pour le mode release
  String _sanitizeMessage(String message) {
    // Masquer les tokens JWT
    final sanitized = message.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'),
      'Bearer [REDACTED]',
    );

    // Masquer les mots de passe
    final sanitized2 = sanitized.replaceAll(
      RegExp(r'password["\s:]+["\s]*[^\s"]+', caseSensitive: false),
      'password: [REDACTED]',
    );

    // Masquer les clés API
    final sanitized3 = sanitized2.replaceAll(
      RegExp(r'api[_-]?key["\s:]+["\s]*[^\s"]+', caseSensitive: false),
      'api_key: [REDACTED]',
    );

    // Masquer les tokens de session
    final sanitized4 = sanitized3.replaceAll(
      RegExp(r'token["\s:]+["\s]*[^\s"]+', caseSensitive: false),
      'token: [REDACTED]',
    );

    return sanitized4;
  }
}

/// Filtre personnalisé pour les logs
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // En release, ne logger que les warnings et erreurs
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}

/// Printer personnalisé pour les logs
class _AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final emoji = _getEmoji(event.level);
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final message = event.message;

    if (kReleaseMode) {
      // Format compact pour release
      return ['$time $emoji $message'];
    }

    // Format détaillé pour debug
    final level = event.level.name.toUpperCase();
    final error = event.error;
    final stack = event.stackTrace;

    final lines = ['$time [$level] $emoji $message'];

    if (error != null) {
      lines.add('Error: $error');
    }

    if (stack != null) {
      lines.add('StackTrace: $stack');
    }

    return lines;
  }

  String _getEmoji(Level level) {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return 'ℹ️';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      default:
        return '📝';
    }
  }
}
