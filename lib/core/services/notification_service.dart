import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../../core/api/base_client.dart';
import '../../core/services/feedback_service.dart';

/// Service de gestion des notifications Firebase
class NotificationService {
  // =========================
  // SINGLETON
  // =========================

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // =========================
  // VARIABLES
  // =========================

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Logger _logger = Logger();

  final BaseClient _baseClient = BaseClient();

  String? _fcmToken;

  bool _isInitialized = false;

  int _notificationIdCounter = 0;

  // =========================
  // GETTER
  // =========================

  String? get fcmToken => _fcmToken;

  // =========================
  // INITIALIZE
  // =========================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i(
        'Initialisation du service notifications...',
      );

      // =========================
      // PERMISSIONS FIREBASE
      // =========================

      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i(
          'Permission notifications accordée',
        );
      } else {
        _logger.w(
          'Permission refusée',
        );
      }

      // =========================
      // INITIALISATION NOTIFICATIONS LOCALES
      // =========================

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
      );

      // =========================
      // TOKEN FCM
      // =========================

      await _getFCMToken();

      // =========================
      // LISTENERS
      // =========================

      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleBackgroundMessage,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen(
        _onTokenRefresh,
      );

      _isInitialized = true;

      _logger.i(
        'Service notifications initialisé',
      );
    } catch (e) {
      _logger.e(
        'Erreur initialisation notifications: $e',
      );
    }
  }

  // =========================
  // GET TOKEN
  // =========================

  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        _fcmToken = token;

        _logger.i(
          'FCM TOKEN: $token',
        );
      }
    } catch (e) {
      _logger.e(
        'Erreur récupération token FCM: $e',
      );
    }
  }

  // =========================
  // FOREGROUND MESSAGE
  // =========================

  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    _logger.i(
      'Message foreground: ${message.messageId}',
    );

    final messageType = message.data['type'];

    // Filtrage spécial pour les nouvelles missions
    if (messageType == 'NEW_MISSION') {
      await _handleNewMissionAlert(message);
    } else {
      // Notification standard pour les autres types
      await _showLocalNotification(
        title: message.notification?.title ?? 'Nouvelle notification',
        body: message.notification?.body ?? 'Vous avez un nouveau message',
        data: message.data,
      );
    }
  }

  /// Gère les alertes de nouvelles missions avec son et SnackBar
  Future<void> _handleNewMissionAlert(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Nouvelle mission disponible!';
    final body = message.notification?.body ??
        'Une opportunité de gain vient d\'apparaître';

    // Notification locale avec son d'alerte
    await _showLocalNotification(
      title: title,
      body: body,
      data: {
        ...message.data,
        'priority': 'high',
        'sound': 'alert',
      },
    );

    // SnackBar spécial pour les missions
    _showMissionSnackBar(title, body, message.data);
  }

  /// Affiche un SnackBar spécial pour les alertes de mission
  void _showMissionSnackBar(
      String title, String body, Map<String, dynamic>? data) {
    // Afficher un SnackBar global via FeedbackService
    FeedbackService.showInfoGlobal('🚨 $title\n$body');
    _logger.i('🚨 Alerte mission: $title - $body');
  }

  // =========================
  // BACKGROUND MESSAGE
  // =========================

  Future<void> _handleBackgroundMessage(
    RemoteMessage message,
  ) async {
    _logger.i(
      'Message background: ${message.messageId}',
    );

    final messageType = message.data['type'];

    // Filtrage spécial pour les nouvelles missions
    if (messageType == 'NEW_MISSION') {
      await _handleNewMissionAlert(message);
    } else {
      await _showLocalNotification(
        title: message.notification?.title ?? 'Nouvelle notification',
        body: message.notification?.body ?? 'Vous avez un nouveau message',
        data: message.data,
      );
    }
  }

  // =========================
  // TOKEN REFRESH
  // =========================

  Future<void> _onTokenRefresh(
    String token,
  ) async {
    _logger.i(
      'Token refresh: $token',
    );

    _fcmToken = token;
  }

  // =========================
  // LOCAL NOTIFICATION
  // =========================

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fonaco_channel',
      'FONACO Notifications',
      channelDescription: 'Notifications de l\'application FONACO',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFD400),
      playSound: true,
      // Son d'alerte spécial pour les missions
      // sound: data?['priority'] == 'high' ? 'alert' : 'default', // TODO: Ajouter fichier son alert
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      _notificationIdCounter++,
      title,
      body,
      notificationDetails,
      payload: data?.toString(),
    );
  }

  // =========================
  // SEND TOKEN TO BACKEND
  // =========================

  Future<void> sendTokenToBackend(
    String accessToken,
  ) async {
    try {
      final token = _fcmToken;
      if (token == null || token.isEmpty) {
        _logger.w('Aucun token FCM à enregistrer');
        return;
      }

      // 1. Envoyer vers l'endpoint de notification (existant)
      await _baseClient.post(
        'notifications/register-device/',
        data: {
          'registration_id': token,
          'type': Platform.isIOS ? 'ios' : 'android',
          'name': 'fonaco_app',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      // 2. Envoyer vers le profil utilisateur (nouveau - spécification API)
      await _baseClient.patch(
        'accounts/profile/',
        data: {
          'fcm_token': token,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      _logger.i('Token FCM enregistré sur le backend et le profil');
    } catch (e) {
      _logger.e('Erreur envoi token FCM au backend: $e');
    }
  }

  // =========================
  // REQUEST PERMISSION ANDROID 13+
  // =========================

  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await androidImplementation?.requestNotificationsPermission();

    return granted ?? false;
  }
}
