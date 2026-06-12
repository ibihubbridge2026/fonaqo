import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:fonaco/core/config/api_config.dart' as core_cfg;
import 'package:fonaco/core/utils/app_logger.dart';

/// Service WebSocket mission-scoped — aligné sur Django `ws/chat/<mission_id>/`.
class ChatWebSocketService {
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  final AppLogger _logger = AppLogger();
  final _uuid = const Uuid();
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _isManuallyDisconnected = false;
  String? _currentMissionId;
  String? _accessToken;
  String? _lastMessageId;

  final StreamController<ChatEvent> _eventController =
      StreamController.broadcast();
  Stream<ChatEvent> get events => _eventController.stream;

  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;
  int _reconnectAttempts = 0;

  String? get currentMissionId => _currentMissionId;
  bool get isConnected => _isConnected;

  /// Connecte au WebSocket d'une mission.
  Future<void> connect({
    required String missionId,
    required String accessToken,
  }) async {
    if (missionId.isEmpty || accessToken.isEmpty) {
      _logger.w('Cannot connect: missing missionId or token');
      return;
    }

    if (_isConnected && _currentMissionId == missionId) return;

    if (_isConnected && _currentMissionId != missionId) {
      disconnect();
    }

    _currentMissionId = missionId;
    _accessToken = accessToken;

    try {
      final wsUrl = Uri.parse(
        '${core_cfg.ApiConfig.wsBaseUrl}/ws/chat/$missionId/?token=$accessToken',
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
    } catch (e) {
      _logger.e('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentMissionId = null;
  }

  String sendMessage({
    required String content,
    String messageType = 'text',
    double? proposedPrice,
  }) {
    final clientMsgId = _uuid.v4();
    if (!_isConnected) {
      _logger.w('Cannot send message: not connected');
      return clientMsgId;
    }
    _send({
      'type': 'message',
      'client_message_id': clientMsgId,
      'content': content,
      'message_type': messageType,
      if (proposedPrice != null) 'proposed_price': proposedPrice,
    });
    return clientMsgId;
  }

  void sendTypingStatus(bool isTyping) {
    if (!_isConnected) return;
    _send({'type': isTyping ? 'typing_start' : 'typing_stop'});
  }

  void markAsRead(List<String> messageIds, {bool conversationOpen = true}) {
    if (!_isConnected) return;
    _send({
      'type': 'mark_read',
      'message_ids': messageIds,
      'conversation_open': conversationOpen,
    });
  }

  void requestCatchup(String? lastMessageId) {
    if (!_isConnected) return;
    _send({
      'type': 'catchup',
      if (lastMessageId != null) 'last_message_id': lastMessageId,
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      _logger.e('Error sending message: $e');
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String;
      _reconnectAttempts = 0;

      if (type == 'message' || type == 'catchup_result') {
        final msg = data['message'] as Map<String, dynamic>?;
        if (msg != null) {
          final id = msg['id']?.toString();
          if (id != null) _lastMessageId = id;
        }
        final msgs = data['messages'] as List<dynamic>?;
        if (msgs != null && msgs.isNotEmpty) {
          _lastMessageId = (msgs.last as Map)['id']?.toString();
        }
      }

      _eventController.add(ChatEvent(type, data));
    } catch (e) {
      _logger.e('Error parsing message: $e');
    }
  }

  void _onError(error) {
    _logger.e('WebSocket error: $error');
    _isConnected = false;
    if (!_isManuallyDisconnected) _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    if (!_isManuallyDisconnected) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts ||
        _currentMissionId == null ||
        _accessToken == null) {
      _eventController.add(ChatEvent('reconnect_failed', null));
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySec = (_reconnectDelay.inSeconds * _reconnectAttempts).clamp(1, 60);
    final delay = Duration(seconds: delaySec);

    _reconnectTimer = Timer(delay, () {
      if (_currentMissionId != null && _accessToken != null) {
        connect(missionId: _currentMissionId!, accessToken: _accessToken!);
        if (_lastMessageId != null) requestCatchup(_lastMessageId);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) _send({'type': 'heartbeat'});
    });
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}

class ChatEvent {
  final String type;
  final Map<String, dynamic>? data;
  ChatEvent(this.type, this.data);
}
