import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/error_mapper.dart';
import '../../widgets/feedback/custom_toast.dart';

/// Service centralisé pour afficher des feedbacks utilisateur
class FeedbackService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static OverlayEntry? _currentOverlay;
  static int _activeToasts = 0;
  static const int _maxActiveToasts = 3;

  // Setter pour initialiser la navigatorKey
  static set navigatorKey(GlobalKey<NavigatorState>? key) {
    _navigatorKey = key;
  }

  static void show(
    BuildContext context, {
    required String message,
    required FeedbackType type,
    Duration? duration,
  }) {
    // Limiter le nombre de toasts simultanés
    if (_activeToasts >= _maxActiveToasts) {
      return;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => CustomToast(
        message: message,
        type: type,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );

    _activeToasts++;
    overlay.insert(entry);
    _currentOverlay = entry;

    // Nettoyer quand le toast est terminé
    Future.delayed(duration ?? const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
        _activeToasts--;
        if (_currentOverlay == entry) {
          _currentOverlay = null;
        }
      }
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: FeedbackType.success);
  }

  static void showError(BuildContext context, dynamic error) {
    final userMessage = ErrorMapper.mapToUserFriendly(error);
    show(context, message: userMessage, type: FeedbackType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: FeedbackType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: FeedbackType.warning);
  }

  static void dismissAll() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _activeToasts = 0;
  }

  // Méthodes globales utilisant navigatorKey
  static void showSuccessGlobal(String message) {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      showSuccess(context, message);
    }
  }

  static void showErrorGlobal(dynamic error) {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      showError(context, error);
    }
  }

  static void showInfoGlobal(String message) {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      showInfo(context, message);
    }
  }

  static void showWarningGlobal(String message) {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      showWarning(context, message);
    }
  }
}

/// Gestionnaire des notifications au premier plan
class ForegroundNotificationManager {
  static void handleForegroundMessage(
      RemoteMessage message, BuildContext context) {
    final title = message.notification?.title ?? 'Nouvelle notification';
    final body = message.notification?.body ?? '';

    // Afficher un toast élégant
    final fullMessage = body.isNotEmpty ? '$title\n$body' : title;
    FeedbackService.showInfo(context, fullMessage);

    // Log pour debug
    print('🔔 Notification foreground: $title');
  }

  static void handleNotificationTap(
      RemoteMessage message, BuildContext context) {
    final title = message.notification?.title ?? 'Notification';
    print('📱 Notification cliquée: $title');

    // TODO: Naviguer vers l'écran approprié selon les données
    // Exemple: if (message.data['type'] == 'new_message') { ... }
  }
}
