import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../api/base_client.dart';

/// Modèle de message pour le chat
class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final String? image;
  final String? audioUrl;
  final Duration? audioDuration;
  final bool isMe;
  final String? type; // 'text', 'image', 'voice'

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.image,
    this.audioUrl,
    this.audioDuration,
    this.isMe = false,
    this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUser) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp']) ?? DateTime.now(),
      image: json['image'],
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'] != null
          ? Duration(seconds: json['audio_duration'])
          : null,
      isMe: json['sender'] == currentUser,
      type: json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'type': type ?? 'text',
      if (image != null) 'image': image,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (audioDuration != null) 'audio_duration': audioDuration!.inSeconds,
    };
  }
}

/// Service de gestion du chat en temps réel via WebSocket
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Logger _logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();

  String? _currentMissionId;
  String? _currentUser;
  bool _isConnected = false;

  // Getters
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get typingStream => _typingController.stream;
  bool get isConnected => _isConnected;
  String? get currentMissionId => _currentMissionId;

  /// Connexion au WebSocket pour une mission spécifique
  Future<void> connect(String missionId, String userId) async {
    if (_isConnected && _currentMissionId == missionId) {
      _logger.d('Déjà connecté à la mission $missionId');
      return;
    }

    await disconnect();

    try {
      _currentMissionId = missionId;
      _currentUser = userId;

      // Construire l'URL WebSocket
      final baseUrl = BaseClient.apiHostAndPort;
      final wsUrl = 'ws://$baseUrl/ws/chat/$missionId/';

      _logger.i('Connexion WebSocket: $wsUrl');

      _channel = IOWebSocketChannel.connect(wsUrl);
      _isConnected = true;
      _connectionController.add(true);

      // Envoyer message de connexion
      _sendMessage({
        'type': 'join',
        'user_id': userId,
        'mission_id': missionId,
      });

      // Écouter les messages entrants
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: true,
      );

      _logger.i('Connecté au chat de la mission $missionId');
    } catch (e) {
      _logger.e('Erreur connexion WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Gestion des messages entrants
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;

      _logger.d('Message reçu: $data');

      switch (data['type']) {
        case 'message':
          final chatMessage = ChatMessage.fromJson(data, _currentUser ?? '');
          _messageController.add(chatMessage);
          break;

        case 'typing':
          _typingController.add(data['user_id'] ?? '');
          break;

        case 'user_status':
          // Gérer le statut en ligne/hors ligne
          _logger.d('Statut utilisateur: ${data['status']}');
          break;

        case 'connection':
          // Message de bienvenue ou confirmation
          _logger.i('Message de connexion: ${data['message']}');
          break;

        default:
          _logger.w('Type de message non géré: ${data['type']}');
      }
    } catch (e) {
      _logger.e('Erreur traitement message: $e');
    }
  }

  /// Gestion des erreurs WebSocket
  void _handleError(dynamic error) {
    _logger.e('Erreur WebSocket: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Gestion de déconnexion
  void _handleDisconnection() {
    _logger.i('Déconnexion WebSocket');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Envoyer un message (texte, image, ou vocal)
  Future<void> sendMessage(dynamic messageData) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Non connecté au chat');
    }

    if (messageData is String) {
      // Message texte simple
      final message = ChatMessage(
        sender: _currentUser ?? '',
        text: messageData,
        timestamp: DateTime.now(),
      );

      _sendMessage({
        'type': 'message',
        ...message.toJson(),
      });
    } else if (messageData is Map<String, dynamic>) {
      // Message complexe (vocal, image, etc.)
      _sendMessage(messageData);
    }
  }

  /// Envoyer une image
  Future<void> sendImage(String imagePath) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Non connecté au chat');
    }

    final message = ChatMessage(
      sender: _currentUser ?? '',
      text: '',
      timestamp: DateTime.now(),
      image: imagePath,
    );

    _sendMessage({
      'type': 'message',
      ...message.toJson(),
    });
  }

  /// Envoyer un signal de "en train d'écrire"
  Future<void> sendTyping() async {
    if (!_isConnected || _channel == null) {
      return;
    }

    _sendMessage({
      'type': 'typing',
      'user_id': _currentUser,
    });
  }

  /// Envoyer un message générique
  void _sendMessage(Map<String, dynamic> message) {
    try {
      final jsonMessage = json.encode(message);
      _channel?.sink.add(jsonMessage);
      _logger.d('Message envoyé: $jsonMessage');
    } catch (e) {
      _logger.e('Erreur envoi message: $e');
    }
  }

  /// Déconnexion du WebSocket
  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        // Envoyer message de déconnexion
        _sendMessage({
          'type': 'leave',
          'user_id': _currentUser,
          'mission_id': _currentMissionId,
        });

        await _subscription?.cancel();
        await _channel?.sink.close();
        _channel = null;
        _subscription = null;
      }

      _isConnected = false;
      _currentMissionId = null;
      _currentUser = null;
      _connectionController.add(false);

      _logger.i('Déconnecté du chat');
    } catch (e) {
      _logger.e('Erreur déconnexion: $e');
    }
  }

  /// Vérifier si un utilisateur est en ligne
  bool isUserOnline(String userId) {
    // TODO: Implémenter le suivi des utilisateurs en ligne
    // Pour l'instant, retourne true si connecté
    return _isConnected;
  }

  /// Obtenir le statut de connexion
  String getConnectionStatus() {
    if (_isConnected) {
      return 'En ligne';
    } else if (_currentMissionId != null) {
      return 'Reconnexion...';
    } else {
      return 'Hors ligne';
    }
  }

  /// Nettoyage des ressources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _typingController.close();
  }
}
