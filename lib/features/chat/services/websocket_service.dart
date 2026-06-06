import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

/// Service WebSocket pour le chat en temps réel
/// Gère la connexion, la reconnexion automatique et les événements
class ChatWebSocketService {
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  final AppLogger _logger = AppLogger();
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _isManuallyDisconnected = false;
  String? _currentConversationId;
  String? _accessToken;

  // Callbacks pour les événements
  final StreamController<ChatEvent> _eventController =
      StreamController.broadcast();
  Stream<ChatEvent> get events => _eventController.stream;

  // Configuration
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;
  int _reconnectAttempts = 0;

  /// Connecte au WebSocket
  Future<void> connect(BuildContext context) async {
    if (_isConnected) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _accessToken = await auth.getAccessToken();

      if (_accessToken == null) {
        _logger.w('No access token available');
        return;
      }

      final wsUrl = Uri.parse(
        'ws://${ApiConfig.wsHost}/ws/chat/?token=$_accessToken',
      );

      _logger.i('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);
      _isManuallyDisconnected = false;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _eventController.add(ChatEvent('connected', null));
      _startHeartbeat();

      _logger.i('WebSocket connected successfully');
    } catch (e) {
      _logger.e('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Déconnecte du WebSocket
  void disconnect() {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _logger.i('WebSocket disconnected manually');
  }

  /// Joint une conversation spécifique
  void joinConversation(String conversationId) {
    if (!_isConnected) {
      _logger.w('Cannot join conversation: not connected');
      return;
    }

    _currentConversationId = conversationId;
    _send({
      'type': 'join_conversation',
      'conversation_id': conversationId,
    });
    _logger.i('Joined conversation: $conversationId');
  }

  /// Quitte la conversation actuelle
  void leaveConversation() {
    if (_currentConversationId == null) return;

    _send({
      'type': 'leave_conversation',
      'conversation_id': _currentConversationId,
    });
    _currentConversationId = null;
    _logger.i('Left conversation');
  }

  /// Envoie un message
  void sendMessage({
    required String conversationId,
    required String content,
    required String messageType,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) {
      _logger.w('Cannot send message: not connected');
      return;
    }

    _send({
      'type': 'message',
      'conversation_id': conversationId,
      'content': content,
      'message_type': messageType,
      'metadata': metadata,
    });
  }

  /// Envoie un indicateur de typing
  void sendTypingStatus(String conversationId, bool isTyping) {
    if (!_isConnected) return;

    _send({
      'type': 'typing',
      'conversation_id': conversationId,
      'is_typing': isTyping,
    });
  }

  /// Marque des messages comme lus
  void markAsRead(String conversationId, List<String> messageIds) {
    if (!_isConnected) return;

    _send({
      'type': 'read_receipt',
      'conversation_id': conversationId,
      'message_ids': messageIds,
    });
  }

  /// Envoie des données brutes
  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
      _logger.d('Sent: ${data['type']}');
    } catch (e) {
      _logger.e('Error sending message: $e');
    }
  }

  /// Gère les messages reçus
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String;

      _logger.d('Received: $type');

      _eventController.add(ChatEvent(type, data));

      // Réinitialiser le compteur de reconnexion sur message reçu
      _reconnectAttempts = 0;
    } catch (e) {
      _logger.e('Error parsing message: $e');
    }
  }

  /// Gère les erreurs
  void _onError(error) {
    _logger.e('WebSocket error: $error');
    _isConnected = false;
    if (!_isManuallyDisconnected) {
      _scheduleReconnect();
    }
  }

  /// Gère la fermeture de connexion
  void _onDone() {
    _logger.i('WebSocket connection closed');
    _isConnected = false;
    _heartbeatTimer?.cancel();

    if (!_isManuallyDisconnected) {
      _scheduleReconnect();
    }
  }

  /// Planifie une reconnexion
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      _eventController.add(ChatEvent('reconnect_failed', null));
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = _reconnectDelay * _reconnectAttempts;
    _logger.w(
        'Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      // Note: Need context to reconnect, will be handled by UI layer
      _eventController.add(ChatEvent('reconnecting', {
        'attempt': _reconnectAttempts,
        'max_attempts': _maxReconnectAttempts,
      }));
    });
  }

  /// Démarre le heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        _send({'type': 'heartbeat'});
      }
    });
  }

  /// Nettoyage
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

/// Événement WebSocket
class ChatEvent {
  final String type;
  final Map<String, dynamic>? data;

  ChatEvent(this.type, this.data);
}

/// Configuration API (référence)
class ApiConfig {
  static String get wsHost => '192.168.1.73:8000';
}
