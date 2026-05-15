import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/error_mapper.dart';

enum FeedbackType { success, error, info, warning }

/// Service centralisé pour afficher des feedbacks utilisateur avec SnackBar
class FeedbackService {
  static GlobalKey<NavigatorState>? _navigatorKey;

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
    final snackBar = _createSnackBar(
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static SnackBar _createSnackBar({
    required String message,
    required FeedbackType type,
    required Duration duration,
  }) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case FeedbackType.success:
        backgroundColor = const Color(0xFFFFD400); // Jaune FONACO
        textColor = Colors.black;
        icon = Icons.check_circle;
        iconColor = Colors.black;
        break;
      case FeedbackType.error:
        backgroundColor = const Color(0xFFE74C3C); // Rouge erreur
        textColor = Colors.white;
        icon = Icons.error_outline;
        iconColor = Colors.white;
        break;
      case FeedbackType.warning:
        backgroundColor = const Color(0xFFF39C12); // Orange
        textColor = Colors.white;
        icon = Icons.warning_amber;
        iconColor = Colors.white;
        break;
      case FeedbackType.info:
        backgroundColor = const Color(0xFF2196F3); // Bleu
        textColor = Colors.white;
        icon = Icons.info_outline;
        iconColor = Colors.white;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
    );
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

  static void dismissCurrent(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
