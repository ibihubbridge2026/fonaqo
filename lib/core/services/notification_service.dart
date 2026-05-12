import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../../core/api/base_client.dart';

/// Service de gestion des notifications Firebase
class NotificationService {
  // =========================
  // SINGLETON
  // =========================

  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // =========================
  // VARIABLES
  // =========================

  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Logger _logger = Logger();

  final BaseClient _baseClient = BaseClient();

  String? _fcmToken;

  bool _isInitialized = false;

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
          await _firebaseMessaging
              .requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
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

      const AndroidInitializationSettings
          androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings
          iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings
          initializationSettings =
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
      final token =
          await _firebaseMessaging.getToken();

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

    await _showLocalNotification(
      title:
          message.notification?.title ??
          'Nouvelle notification',
      body:
          message.notification?.body ??
          'Vous avez un nouveau message',
      data: message.data,
    );
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

    await _showLocalNotification(
      title:
          message.notification?.title ??
          'Nouvelle notification',
      body:
          message.notification?.body ??
          'Vous avez un nouveau message',
      data: message.data,
    );
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
    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      'fonaco_channel',
      'FONACO Notifications',
      channelDescription:
          'Notifications de l\'application FONACO',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFD400),
      playSound: true,
    );

    const DarwinNotificationDetails
        iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails
        notificationDetails =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
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

      _logger.i('Token FCM enregistré sur le backend');
    } catch (e) {
      _logger.e('Erreur envoi token FCM au backend: $e');
    }
  }

  // =========================
  // REQUEST PERMISSION ANDROID 13+
  // =========================

  Future<bool>
      requestNotificationPermission() async {
    if (Platform.isIOS) {
      return true;
    }

    final androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await androidImplementation
            ?.requestNotificationsPermission();

    return granted ?? false;
  }
}