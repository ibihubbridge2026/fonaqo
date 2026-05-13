import 'dart:async';
import 'dart:convert';
<<<<<<< HEAD
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
=======

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Erreur métier (ex. identifiant de mission invalide).
class ChatConnectionException implements Exception {
  final String message;
  ChatConnectionException(this.message);

  @override
  String toString() => message;
}
>>>>>>> a9a7cb4 (mise en place de mission)

class ChatWebSocketMessage {
  final String id;
  final String content;
  final String sender;
  final DateTime timestamp;
  final bool isMe;

  ChatWebSocketMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatWebSocketMessage.fromJson(
<<<<<<< HEAD
      Map<String, dynamic> json, String currentUsername) {
    return ChatWebSocketMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? json['message'] ?? '',
      sender: json['sender'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isMe: json['sender'] == currentUsername,
=======
    Map<String, dynamic> json,
    String currentUsername,
  ) {
    final senderName = json['sender']?.toString() ?? '';
    return ChatWebSocketMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? json['message'] ?? '',
      sender: senderName,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isMe: senderName.isNotEmpty && senderName == currentUsername,
>>>>>>> a9a7cb4 (mise en place de mission)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
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
<<<<<<< HEAD

  // Getters
=======
  String? _lastError;

>>>>>>> a9a7cb4 (mise en place de mission)
  List<ChatWebSocketMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;
  String? get currentMissionId => _currentMissionId;
<<<<<<< HEAD

  // Stream controller pour les messages en temps réel
=======
  String? get lastError => _lastError;

>>>>>>> a9a7cb4 (mise en place de mission)
  final StreamController<ChatWebSocketMessage> _messageController =
      StreamController<ChatWebSocketMessage>.broadcast();
  final StreamController<bool> _typingController =
      StreamController<bool>.broadcast();

  Stream<ChatWebSocketMessage> get messageStream => _messageController.stream;
  Stream<bool> get typingStream => _typingController.stream;

<<<<<<< HEAD
  Future<void> connect(String missionId) async {
=======
  static bool isValidMissionUuid(String missionId) {
    final re = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return re.hasMatch(missionId.trim());
  }

  Future<void> connect(String missionId) async {
    _lastError = null;
    if (!isValidMissionUuid(missionId)) {
      _isConnected = false;
      notifyListeners();
      throw ChatConnectionException(
        'Identifiant de mission invalide. Impossible d’ouvrir le chat.',
      );
    }

>>>>>>> a9a7cb4 (mise en place de mission)
    if (_isConnected && _currentMissionId == missionId) {
      _logger.d('Déjà connecté à la mission $missionId');
      return;
    }

<<<<<<< HEAD
    try {
      // Récupérer le token JWT depuis le stockage sécurisé
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null) {
        throw Exception('Token JWT non disponible');
      }

      // Construire l'URL WebSocket avec authentification
      final baseUrl = 'http://192.168.1.73:8000'; // Même config que BaseClient
      final wsUrl =
          Uri.parse('${baseUrl.replaceFirst('http', 'ws')}/ws/chat/$missionId/')
              .replace(queryParameters: {'token': token});

      _logger.i('Connexion WebSocket: $wsUrl');

      // Créer le channel WebSocket
      _channel = WebSocketChannel.connect(wsUrl);
      _currentMissionId = missionId;

      // Écouter les messages
=======
    await disconnect();

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        throw ChatConnectionException(
          'Session expirée. Reconnectez-vous pour utiliser le chat.',
        );
      }

      const baseUrl = 'http://192.168.1.73:8000';
      final wsUrl = Uri.parse(
        '${baseUrl.replaceFirst('http', 'ws')}/ws/chat/$missionId/',
      ).replace(queryParameters: {'token': token});

      _logger.i('Connexion WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);
      _currentMissionId = missionId;

>>>>>>> a9a7cb4 (mise en place de mission)
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
<<<<<<< HEAD
        cancelOnError: true,
=======
        cancelOnError: false,
>>>>>>> a9a7cb4 (mise en place de mission)
      );

      _isConnected = true;
      notifyListeners();

      _logger.i('Connecté au chat de la mission $missionId');
    } catch (e) {
      _logger.e('Erreur de connexion WebSocket: $e');
      _isConnected = false;
<<<<<<< HEAD
      notifyListeners();
      rethrow;
=======
      _lastError = e.toString();
      notifyListeners();
      if (e is ChatConnectionException) rethrow;
      throw ChatConnectionException(
        'Connexion au chat impossible. Vérifiez le réseau et le serveur.',
      );
>>>>>>> a9a7cb4 (mise en place de mission)
    }
  }

  void _handleMessage(dynamic message) {
    try {
<<<<<<< HEAD
      final data = jsonDecode(message) as Map<String, dynamic>;
=======
      final data = jsonDecode(message as String) as Map<String, dynamic>;
>>>>>>> a9a7cb4 (mise en place de mission)

      if (data['type'] == 'typing') {
        _isTyping = data['is_typing'] ?? false;
        _typingController.add(_isTyping);
        notifyListeners();
      } else {
<<<<<<< HEAD
        // Message normal
=======
>>>>>>> a9a7cb4 (mise en place de mission)
        final currentUsername = _getCurrentUsername();
        final chatMessage =
            ChatWebSocketMessage.fromJson(data, currentUsername);

        _messages.add(chatMessage);
        _messageController.add(chatMessage);
        notifyListeners();

        _logger.d('Message reçu: ${chatMessage.content}');
      }
    } catch (e) {
      _logger.e('Erreur traitement message WebSocket: $e');
    }
  }

  void _handleError(dynamic error) {
    _logger.e('Erreur WebSocket: $error');
    _isConnected = false;
<<<<<<< HEAD
=======
    _lastError = error.toString();
>>>>>>> a9a7cb4 (mise en place de mission)
    notifyListeners();
  }

  void _handleDisconnect() {
    _logger.i('WebSocket déconnecté');
    _isConnected = false;
    _isTyping = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (!_isConnected || _channel == null) {
<<<<<<< HEAD
      throw Exception('Non connecté au WebSocket');
=======
      throw ChatConnectionException('Chat non connecté.');
>>>>>>> a9a7cb4 (mise en place de mission)
    }

    if (content.trim().isEmpty) {
      return;
    }

    try {
      final message = {
        'type': 'message',
        'message': content.trim(),
      };

      _channel!.sink.add(jsonEncode(message));
      _logger.d('Message envoyé: $content');
    } catch (e) {
      _logger.e('Erreur envoi message: $e');
      rethrow;
    }
  }

  Future<void> sendTyping(bool isTyping) async {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      final message = {
        'type': 'typing',
        'is_typing': isTyping,
      };

      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      _logger.e('Erreur envoi statut typing: $e');
    }
  }

  Future<void> disconnect() async {
<<<<<<< HEAD
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    if (_subscription != null) {
      await _subscription?.cancel();
      _subscription = null;
    }
=======
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
>>>>>>> a9a7cb4 (mise en place de mission)

    _isConnected = false;
    _isTyping = false;
    _currentMissionId = null;
    notifyListeners();

<<<<<<< HEAD
    _logger.i('WebSocket déconnecté');
=======
    _logger.i('WebSocket déconnecté (manuel)');
>>>>>>> a9a7cb4 (mise en place de mission)
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  String _getCurrentUsername() {
<<<<<<< HEAD
    if (_currentUsername != null) return _currentUsername!;

    // Essayer de récupérer depuis AuthProvider
    try {
      // Note: Ceci nécessite d'avoir accès au contexte ou au provider
      // Pour l'instant, on utilise une valeur par défaut
      _currentUsername = 'current_user';
    } catch (e) {
      _currentUsername = 'current_user';
    }

    return _currentUsername!;
=======
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      return _currentUsername!;
    }
    return '';
>>>>>>> a9a7cb4 (mise en place de mission)
  }

  void setCurrentUsername(String username) {
    _currentUsername = username;
  }

<<<<<<< HEAD
  // Méthode pour ajouter des messages historiques
=======
>>>>>>> a9a7cb4 (mise en place de mission)
  void addHistoricalMessage(ChatWebSocketMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
<<<<<<< HEAD
    disconnect();
=======
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    _isTyping = false;
    _currentMissionId = null;
>>>>>>> a9a7cb4 (mise en place de mission)
    _messageController.close();
    _typingController.close();
    super.dispose();
  }
}
