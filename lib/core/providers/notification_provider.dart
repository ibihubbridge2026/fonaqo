import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/api_service.dart';
import '../services/memory_auth_cache.dart';
import '../config/api_config.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = false;

  StreamSubscription? _notificationSubscription;
  StreamSubscription? _messageSubscription;
  WebSocketChannel? _socketChannel;
  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);

  // Getters
  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;
  bool get isLoading => _isLoading;

  // Cache keys
  static const String _cacheNotificationsKey = 'cached_unread_notifications';
  static const String _cacheMessagesKey = 'cached_unread_messages';

  NotificationProvider() {
    _loadFromCache();
    _initializeRealtimeUpdates();
  }

  /// Load cached counts from SharedPreferences
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

  /// Save counts to SharedPreferences
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cacheNotificationsKey, _unreadNotifications);
      await prefs.setInt(_cacheMessagesKey, _unreadMessages);
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Initialize WebSocket connection for real-time updates
  void _initializeRealtimeUpdates() {
    _connectWebSocket();
  }

  /// Connect to WebSocket for real-time notifications
  void _connectWebSocket() {
    final token = MemoryAuthCache().accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('No token available, falling back to polling');
      _startPolling();
      return;
    }

    try {
      // Nettoyer le token pour éviter les caractères parasites (#, espaces, etc.)
      final cleanToken =
          token.trim().replaceAll('#', '').replaceAll(RegExp(r'\s'), '');

      final baseUrl = ApiConfig.serverUrl;
      final wsUrl =
          Uri.parse('${baseUrl.replaceFirst('http', 'ws')}/ws/notifications/')
              .replace(queryParameters: {'token': cleanToken});

      _socketChannel = WebSocketChannel.connect(wsUrl);
      debugPrint('WebSocket notifications connected: $wsUrl');

      _socketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      _pollingTimer?.cancel();
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('WebSocket notification event: $type');

      switch (type) {
        case 'notification_created':
          _unreadNotifications++;
          _saveToCache();
          notifyListeners();
          break;
        case 'unread_count_updated':
          _unreadNotifications =
              data['unread_notifications'] as int? ?? _unreadNotifications;
          _unreadMessages = data['unread_messages'] as int? ?? _unreadMessages;
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

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    debugPrint('WebSocket error: $error');
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleWebSocketDone() {
    debugPrint('WebSocket disconnected');
    _scheduleReconnect();
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached, falling back to polling');
      _startPolling();
      return;
    }

    final delay = Duration(
        milliseconds:
            _initialReconnectDelay.inMilliseconds * (1 << _reconnectAttempts));

    debugPrint(
        'Scheduling reconnection in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connectWebSocket();
    });
  }

  /// Start polling for updates (fallback if WebSocket not available)
  void _startPolling() {
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketChannel?.sink.close();

    // Polling unique au lieu de périodique
    refreshCounts();

    // Retenter la connexion WebSocket après 5 minutes
    _reconnectTimer = Timer(const Duration(minutes: 5), () {
      _reconnectAttempts = 0;
      _connectWebSocket();
    });
  }

  /// Refresh counts from API
  Future<void> refreshCounts() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch unread notifications count
      final notificationsResponse =
          await _apiService.get('/notifications/unread-count');
      if (notificationsResponse != null &&
          notificationsResponse['count'] != null) {
        _unreadNotifications = notificationsResponse['count'] as int;
      }

      // Fetch unread messages count
      final messagesResponse =
          await _apiService.get('/conversations/unread-count');
      if (messagesResponse != null && messagesResponse['count'] != null) {
        _unreadMessages = messagesResponse['count'] as int;
      }

      await _saveToCache();
    } catch (e) {
      debugPrint('Error refreshing counts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually increment notification count (for local updates)
  void incrementNotifications() {
    _unreadNotifications++;
    _saveToCache();
    notifyListeners();
  }

  /// Manually increment message count (for local updates)
  void incrementMessages() {
    _unreadMessages++;
    _saveToCache();
    notifyListeners();
  }

  /// Mark a single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.post('/notifications/$notificationId/read/');
      _unreadNotifications =
          (_unreadNotifications > 0) ? _unreadNotifications - 1 : 0;
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markNotificationsAsRead() async {
    try {
      await _apiService.post('/notifications/mark-all-read');
      _unreadNotifications = 0;
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  /// Mark all messages as read
  Future<void> markMessagesAsRead() async {
    try {
      await _apiService.post('/conversations/mark-all-read');
      _unreadMessages = 0;
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _notificationSubscription?.cancel();
    _messageSubscription?.cancel();
    _socketChannel?.sink.close();
    super.dispose();
  }
}
