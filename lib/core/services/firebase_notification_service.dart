import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fonaco/core/utils/app_logger.dart';

/// Service pour les notifications Firebase FCM
/// Gère l'enregistrement du token, la réception des notifications
/// et l'affichage des notifications locales
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final AppLogger _logger = AppLogger();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    // Initialiser les notifications locales
    await _initializeLocalNotifications();

    // Demander la permission de notification
    await _requestPermission();

    // Obtenir le token FCM
    await _getFCMToken();

    // Configurer les listeners
    _configureMessageListeners();

    _logger.i('Firebase Notification Service initialized');
  }

  /// Initialise les notifications locales pour Android/iOS
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  /// Demande la permission de notification
  Future<void> _requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i(
          'Notification permission granted: ${settings.authorizationStatus}');
    }
  }

  /// Obtient le token FCM
  Future<String?> getFCMToken() async {
    await _getFCMToken();
    return _fcmToken;
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        _logger.i('FCM Token obtained: ${_fcmToken!.substring(0, 10)}...');

        // Envoyer le token au serveur
        await _sendTokenToServer(_fcmToken!);
      }

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _logger.i('FCM Token refreshed');
        _sendTokenToServer(token);
      });
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
    }
  }

  /// Envoie le token FCM au serveur
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Implémenter l'envoi du token au serveur via API
      _logger.d('Sending FCM token to server...');
    } catch (e) {
      _logger.e('Error sending FCM token to server: $e');
    }
  }

  /// Configure les listeners de messages
  void _configureMessageListeners() {
    // Message reçu quand l'app est en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger
          .i('Received message in foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Message reçu quand l'app est en background mais ouverte
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger
          .i('Message opened from background: ${message.notification?.title}');
      _handleMessageNavigation(message);
    });

    // Message reçu quand l'app est terminée
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _logger.i('Message opened from terminated state');
        _handleMessageNavigation(message);
      }
    });
  }

  /// Affiche une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fonaqo_channel',
        'FONAQO Notifications',
        channelDescription: 'Notifications pour les missions et le chat',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    }
  }

  /// Gère la navigation depuis une notification
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    // TODO: Implémenter la navigation selon le type de notification
    // Ex: mission, chat, wallet, etc.
    _logger.d('Navigate to: type=$type, id=$id');
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      // TODO: Appeler l'API pour marquer comme lu
      _logger.d('Marking notification as read: $notificationId');
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      // TODO: Appeler l'API pour marquer toutes comme lues
      _logger.d('Marking all notifications as read');
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
    }
  }

  /// S'abonne à un topic FCM
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to topic: $e');
    }
  }

  /// Se désabonne d'un topic FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from topic: $e');
    }
  }

  /// Supprime le token FCM (logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      _logger.i('FCM Token deleted');
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }

  // Getters
  String? get fcmToken => _fcmToken;
}
