import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  bool _isReconnecting = false;

  String? _currentMissionId;
  String? _currentUsername;
  String? _lastError;

  // Auto-reconnect configuration
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  /// Getters
  List<ChatWebSocketMessage> get messages => List.unmodifiable(_messages);

  bool get isConnected => _isConnected;
  
  bool get isReconnecting => _isReconnecting;

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
        onDone: _handleDisconnectWithReconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0; // Reset reconnect attempts on successful connection
      
      // Start heartbeat
      _startHeartbeat();

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

  /// Déconnexion WebSocket avec auto-reconnect
  void _handleDisconnectWithReconnect() {
    _logger.i('WebSocket déconnecté, tentative de reconnexion...');
    
    _isConnected = false;
    _isTyping = false;
    
    // Annuler le heartbeat
    _heartbeatTimer?.cancel();
    
    notifyListeners();
    
    // Programmer la reconnexion si ce n'est pas une déconnexion manuelle
    if (_currentMissionId != null && !_isReconnecting) {
      _scheduleReconnect();
    }
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
      _subscription?.cancel();
      _subscription = null;

      _channel?.sink.close();
      _channel = null;
    } catch (e) {
      _logger.e('Erreur fermeture WebSocket : $e');
    }

    _isConnected = false;
    _isTyping = false;
    _currentMissionId = null;

    // Annuler les timers
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _isReconnecting = false;

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

  // =========================
  // AUTO-RECONNECT & HEARTBEAT
  // =========================

  /// Démarrer le heartbeat pour maintenir la connexion active
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _sendHeartbeat();
        } catch (e) {
          _logger.e('Erreur heartbeat: $e');
          _handleHeartbeatFailure();
        }
      }
    });
  }

  /// Envoyer un message heartbeat
  void _sendHeartbeat() {
    final heartbeat = {
      'type': 'heartbeat',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel!.sink.add(jsonEncode(heartbeat));
    _logger.d('Heartbeat envoyé');
  }

  /// Gérer l'échec du heartbeat
  void _handleHeartbeatFailure() {
    _logger.w('Heartbeat échoué, tentative de reconnexion...');
    _scheduleReconnect();
  }

  /// Programmer la reconnexion
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Nombre maximum de tentatives de reconnexion atteint');
      _lastError = 'Impossible de se reconnecter après $_maxReconnectAttempts tentatives';
      notifyListeners();
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    
    // Calculer le délai avec backoff exponentiel
    final delay = Duration(
      seconds: min(
        _reconnectDelay.inSeconds * (1 << (_reconnectAttempts - 1)),
        _maxReconnectDelay.inSeconds,
      ),
    );

    _logger.i('Tentative de reconnexion $_reconnectAttempts/$_maxReconnectAttempts dans ${delay.inSeconds}s');
    
    _reconnectTimer = Timer(delay, () {
      _attemptReconnect();
    });
    
    notifyListeners();
  }

  /// Tenter de se reconnecter
  Future<void> _attemptReconnect() async {
    if (_currentMissionId == null) {
      _logger.w('Aucune mission à reconnecter');
      return;
    }

    try {
      _logger.i('Tentative de reconnexion à la mission $_currentMissionId...');
      await connect(_currentMissionId!);
      _isReconnecting = false;
      _logger.i('Reconnexion réussie');
    } catch (e) {
      _logger.e('Échec de la reconnexion: $e');
      _isReconnecting = false;
      
      // Programmer une nouvelle tentative
      _scheduleReconnect();
    }
    
    notifyListeners();
  }

  /// Connexion automatique dès l'acceptation de mission
  Future<void> connectOnMissionAcceptance(String missionId) async {
    _logger.i('Connexion automatique au chat pour la mission $missionId');
    
    // Se connecter immédiatement
    await connect(missionId);
    
    // Envoyer un message système
    final systemMessage = {
      'type': 'system',
      'content': 'Chat connecté automatiquement - Mission acceptée',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(systemMessage));
    }
  }

  /// Forcer la reconnexion manuelle
  Future<void> forceReconnect() async {
    _logger.i('Forcer la reconnexion manuelle...');
    
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    
    if (_currentMissionId != null) {
      await _attemptReconnect();
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _typingController.close();
    
    super.dispose();
  }
}
