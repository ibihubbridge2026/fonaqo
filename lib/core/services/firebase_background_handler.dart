import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Handler top-level pour les messages Firebase en background
/// Doit être une fonction top-level pour que Firebase puisse l'appeler
/// même lorsque l'application est complètement fermée

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final Logger logger = Logger();

  logger.i('📨 Background message received: ${message.messageId}');
  logger.d('Message data: ${message.data}');
  logger.d('Message notification: ${message.notification}');

  // Initialisation des notifications locales pour le background
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configuration Android pour les notifications background
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Filtrage spécial pour les nouvelles missions
  final messageType = message.data['type'];

  if (messageType == 'NEW_MISSION') {
    await _handleNewMissionInBackground(
        message, flutterLocalNotificationsPlugin, logger);
  } else {
    await _handleStandardNotificationInBackground(
        message, flutterLocalNotificationsPlugin, logger);
  }
}

/// Gère les alertes de nouvelles missions en background
Future<void> _handleNewMissionInBackground(
  RemoteMessage message,
  FlutterLocalNotificationsPlugin plugin,
  Logger logger,
) async {
  final title = message.notification?.title ?? 'Nouvelle mission disponible!';
  final body = message.notification?.body ??
      'Une opportunité de gain vient d\'apparaître';

  logger.i('🚨 Alerte mission en background: $title - $body');

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'fonaco_mission_channel',
    'FONACO Missions',
    channelDescription: 'Alertes de missions pour agents FONACO',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFFFFD400),
    playSound: true,
    enableVibration: true,
    // vibrationPattern: [0, 1000, 500, 1000], // Pattern d'alerte spécial
  );

  NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await plugin.show(
    0, // ID unique pour les missions
    title,
    body,
    notificationDetails,
    payload: 'NEW_MISSION:${message.data['mission_id'] ?? ''}',
  );
}

/// Gère les notifications standard en background
Future<void> _handleStandardNotificationInBackground(
  RemoteMessage message,
  FlutterLocalNotificationsPlugin plugin,
  Logger logger,
) async {
  final title = message.notification?.title ?? 'Nouvelle notification';
  final body = message.notification?.body ?? 'Vous avez un nouveau message';

  logger.i('📢 Notification standard en background: $title');

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'fonaco_channel',
    'FONACO Notifications',
    channelDescription: 'Notifications de l\'application FONACO',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFFFD400),
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000), // ID unique
    title,
    body,
    notificationDetails,
    payload: message.data.toString(),
  );
}
