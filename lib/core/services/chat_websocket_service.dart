import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';

/// Exception personnalisée pour les erreurs de chat
class ChatConnectionException implements Exception {
  final String message;

  ChatConnectionException(this.message);

  @override
  String toString() => message;
}

/// Modèle de message WebSocket
class ChatWebSocketMessage {
  final String id;
  final String content;
  final String sender;
  final DateTime timestamp;
  final bool isMe;

  const ChatWebSocketMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatWebSocketMessage.fromJson(
    Map<String, dynamic> json,
    String currentUsername,
  ) {
    final senderName = json['sender']?.toString() ?? '';

    return ChatWebSocketMessage(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      sender: senderName,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isMe: senderName == currentUsername,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatWebSocketService extends ChangeNotifier {
  final Logger _logger = Logger();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final List<ChatWebSocketMessage> _messages = [];

  bool _isConnected = false;
  bool _isTyping = false;

  String? _currentMissionId;
  String? _currentUsername;
  String? _lastError;

  /// Getters
  List<ChatWebSocketMessage> get messages => List.unmodifiable(_messages);

  bool get isConnected => _isConnected;

  bool get isTyping => _isTyping;

  String? get currentMissionId => _currentMissionId;

  String? get lastError => _lastError;

  /// Streams
  final StreamController<ChatWebSocketMessage> _messageController =
      StreamController<ChatWebSocketMessage>.broadcast();

  final StreamController<bool> _typingController =
      StreamController<bool>.broadcast();

  Stream<ChatWebSocketMessage> get messageStream => _messageController.stream;

  Stream<bool> get typingStream => _typingController.stream;

  /// Validation UUID mission
  static bool isValidMissionUuid(String missionId) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    );

    return regex.hasMatch(missionId.trim());
  }

  /// Connexion WebSocket
  Future<void> connect(String missionId) async {
    _lastError = null;

    if (!isValidMissionUuid(missionId)) {
      _isConnected = false;
      notifyListeners();

      throw ChatConnectionException(
        'Identifiant de mission invalide.',
      );
    }

    if (_isConnected && _currentMissionId == missionId) {
      _logger.d('Déjà connecté à cette mission.');
      return;
    }

    await disconnect();

    try {
      const storage = FlutterSecureStorage();

      final token = await storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw ChatConnectionException(
          'Token utilisateur introuvable.',
        );
      }

      final baseUrl = ApiConfig.serverUrl;

      final wsUrl = Uri.parse(
        '${baseUrl.replaceFirst('http', 'ws')}/ws/chat/$missionId/',
      ).replace(
        queryParameters: {
          'token': token,
        },
      );

      _logger.i('Connexion WebSocket : $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      _currentMissionId = missionId;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;

      notifyListeners();

      _logger.i('Connexion WebSocket réussie.');
    } catch (e) {
      _logger.e('Erreur connexion WebSocket : $e');

      _isConnected = false;
      _lastError = e.toString();

      notifyListeners();

      if (e is ChatConnectionException) {
        rethrow;
      }

      throw ChatConnectionException(
        'Impossible de se connecter au chat.',
      );
    }
  }

  /// Réception message
  void _handleMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;

      if (data['type'] == 'typing') {
        _isTyping = data['is_typing'] ?? false;

        _typingController.add(_isTyping);

        notifyListeners();

        return;
      }

      final currentUsername = _getCurrentUsername();

      final message = ChatWebSocketMessage.fromJson(
        data,
        currentUsername,
      );

      _messages.add(message);

      _messageController.add(message);

      notifyListeners();

      _logger.d('Message reçu : ${message.content}');
    } catch (e) {
      _logger.e('Erreur traitement message : $e');
    }
  }

  /// Gestion erreur WebSocket
  void _handleError(dynamic error) {
    _logger.e('Erreur WebSocket : $error');

    _isConnected = false;
    _lastError = error.toString();

    notifyListeners();
  }

  /// Déconnexion WebSocket
  void _handleDisconnect() {
    _logger.i('WebSocket déconnecté.');

    _isConnected = false;
    _isTyping = false;

    notifyListeners();
  }

  /// Envoyer message
  Future<void> sendMessage(String content) async {
    if (!_isConnected || _channel == null) {
      throw ChatConnectionException(
        'WebSocket non connecté.',
      );
    }

    if (content.trim().isEmpty) {
      return;
    }

    try {
      final payload = {
        'type': 'message',
        'message': content.trim(),
      };

      _channel!.sink.add(jsonEncode(payload));

      _logger.d('Message envoyé : $content');
    } catch (e) {
      _logger.e('Erreur envoi message : $e');

      rethrow;
    }
  }

  /// Envoyer état typing
  Future<void> sendTyping(bool isTyping) async {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      final payload = {
        'type': 'typing',
        'is_typing': isTyping,
      };

      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      _logger.e('Erreur typing : $e');
    }
  }

  /// Déconnexion manuelle
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      _subscription = null;

      await _channel?.sink.close();
      _channel = null;
    } catch (e) {
      _logger.e('Erreur fermeture WebSocket : $e');
    }

    _isConnected = false;
    _isTyping = false;
    _currentMissionId = null;

    notifyListeners();

    _logger.i('Déconnexion manuelle.');
  }

  /// Ajouter historique
  void addHistoricalMessage(ChatWebSocketMessage message) {
    _messages.add(message);

    notifyListeners();
  }

  /// Nettoyer messages
  void clearMessages() {
    _messages.clear();

    notifyListeners();
  }

  /// Username courant
  String _getCurrentUsername() {
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      return _currentUsername!;
    }

    return '';
  }

  /// Définir username
  void setCurrentUsername(String username) {
    _currentUsername = username;
  }

  @override
  void dispose() {
    _subscription?.cancel();

    try {
      _channel?.sink.close();
    } catch (_) {}

    _messageController.close();
    _typingController.close();

    super.dispose();
  }
}
