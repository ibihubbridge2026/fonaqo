import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = false;

  StreamSubscription? _notificationSubscription;
  StreamSubscription? _messageSubscription;
  WebSocketChannel? _socketChannel;

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
    // TODO: Replace with actual WebSocket URL from backend
    // For now, we'll use polling as a fallback
    _startPolling();
  }

  /// Start polling for updates (fallback if WebSocket not available)
  void _startPolling() {
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      await refreshCounts();
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
      notifyListeners();
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
    _notificationSubscription?.cancel();
    _messageSubscription?.cancel();
    _socketChannel?.sink.close();
    super.dispose();
  }
}
