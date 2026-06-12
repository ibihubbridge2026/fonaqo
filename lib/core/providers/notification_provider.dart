import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/memory_auth_cache.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = false;

  WebSocketChannel? _socketChannel;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);

  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;
  bool get isLoading => _isLoading;

  static const String _cacheNotificationsKey = 'cached_unread_notifications';
  static const String _cacheMessagesKey = 'cached_unread_messages';

  NotificationProvider() {
    _loadFromCache();
  }

  /// À appeler après login / restauration de session.
  Future<void> reconnectAfterAuth() async {
    _reconnectAttempts = 0;
    await refreshCounts();
    _connectWebSocket();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unreadNotifications = prefs.getInt(_cacheNotificationsKey) ?? 0;
      _unreadMessages = prefs.getInt(_cacheMessagesKey) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheNotificationsKey, _unreadNotifications);
      await prefs.setInt(_cacheMessagesKey, _unreadMessages);
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  void _connectWebSocket() {
    final token = MemoryAuthCache().accessToken;
    if (token == null || token.isEmpty) {
      _startPolling();
      return;
    }

    try {
      final cleanToken =
          token.trim().replaceAll('#', '').replaceAll(RegExp(r'\s'), '');
      final baseUrl = ApiConfig.serverUrl;
      final wsUrl = Uri.parse(
        '${baseUrl.replaceFirst('http', 'ws')}/ws/notifications/',
      ).replace(queryParameters: {'token': cleanToken});

      _socketChannel?.sink.close();
      _socketChannel = WebSocketChannel.connect(wsUrl);

      _socketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      _pollingTimer?.cancel();
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'notification_created':
          _unreadNotifications++;
          _saveToCache();
          notifyListeners();
          break;
        case 'unread_count_updated':
          _unreadNotifications =
              data['unread_notifications'] as int? ?? _unreadNotifications;
          _unreadMessages =
              data['unread_messages'] as int? ?? _unreadMessages;
          _saveToCache();
          notifyListeners();
          break;
        case 'message_received':
          _unreadMessages++;
          _saveToCache();
          notifyListeners();
          break;
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _startPolling();
      return;
    }

    final delay = Duration(
      milliseconds:
          _initialReconnectDelay.inMilliseconds * (1 << _reconnectAttempts),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connectWebSocket();
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketChannel?.sink.close();
    refreshCounts();
    _reconnectTimer = Timer(const Duration(minutes: 5), () {
      _reconnectAttempts = 0;
      _connectWebSocket();
    });
  }

  int _extractCount(dynamic response, {List<String> keys = const ['unread_count', 'count']}) {
    if (response == null) return 0;
    if (response is Map) {
      final data = response['data'];
      if (data is Map) {
        for (final key in keys) {
          if (data[key] != null) return data[key] as int;
        }
      }
      for (final key in keys) {
        if (response[key] != null) return response[key] as int;
      }
    }
    return 0;
  }

  Future<void> refreshCounts() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final notificationsResponse =
          await _apiService.get('notifications/unread-count/');
      _unreadNotifications = _extractCount(notificationsResponse);

      await _saveToCache();
    } catch (e) {
      debugPrint('Error refreshing counts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void incrementNotifications() {
    _unreadNotifications++;
    _saveToCache();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.post('notifications/$notificationId/mark-read/');
      _unreadNotifications =
          (_unreadNotifications > 0) ? _unreadNotifications - 1 : 0;
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markNotificationsAsRead() async {
    try {
      await _apiService.post('notifications/mark-all-read/');
      _unreadNotifications = 0;
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketChannel?.sink.close();
    super.dispose();
  }
}
