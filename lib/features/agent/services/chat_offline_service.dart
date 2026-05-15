import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';

/// Service pour gérer les messages hors ligne et le retry automatique
class ChatOfflineService {
  static final ChatOfflineService _instance = ChatOfflineService._internal();
  factory ChatOfflineService() => _instance;
  ChatOfflineService._internal();

  final List<Map<String, dynamic>> _pendingMessages = [];
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  WebSocketChannel? _chatWebSocket;
  bool _isConnected = false;
  Timer? _retryTimer;

  /// Initialise le service
  Future<void> initialize() async {
    await _loadPendingMessages();
    _setupConnectivityListener();
  }

  /// Charge les messages en attente depuis le stockage local
  Future<void> _loadPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getStringList('pending_messages') ?? [];
      
      _pendingMessages.clear();
      for (final jsonStr in pendingJson) {
        final message = json.decode(jsonStr) as Map<String, dynamic>;
        _pendingMessages.add(message);
      }
      
      print('Messages en attente chargés: ${_pendingMessages.length}');
    } catch (e) {
      print('Erreur chargement messages en attente: $e');
    }
  }

  /// Sauvegarde les messages en attente dans le stockage local
  Future<void> _savePendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = _pendingMessages.map((msg) => json.encode(msg)).toList();
      await prefs.setStringList('pending_messages', pendingJson);
    } catch (e) {
      print('Erreur sauvegarde messages en attente: $e');
    }
  }

  /// Configure l'écouteur de connectivité
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isConnected) {
        // Retour de connexion, tenter de se reconnecter et d'envoyer les messages en attente
        _retryPendingMessages();
      }
    });
  }

  /// Connecte au WebSocket chat
  Future<void> connectToChat(String missionId, Function(Map<String, dynamic>) onMessage) async {
    try {
      final wsUrl = 'ws://${ApiConfig.apiHostAndPort}/ws/chat/$missionId/';
      _chatWebSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

      _chatWebSocket!.stream.listen(
        (data) {
          final message = json.decode(data) as Map<String, dynamic>;
          onMessage(message);
        },
        onError: (error) {
          print('Erreur WebSocket chat: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket chat déconnecté');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('Connecté au chat WebSocket');
    } catch (e) {
      print('Erreur connexion chat WebSocket: $e');
      _isConnected = false;
    }
  }

  /// Envoie un message (avec gestion hors ligne)
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    // Ajouter le timestamp et le statut pending
    final messageWithMeta = {
      ...message,
      'timestamp': DateTime.now().toIso8601String(),
      'is_pending': true,
      'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    // Si connecté, essayer d'envoyer directement
    if (_isConnected && _chatWebSocket != null) {
      try {
        _chatWebSocket!.sink.add(json.encode(message));
        
        // Si l'envoi réussit, ne pas ajouter à la queue
        return true;
      } catch (e) {
        print('Échec envoi direct, ajout à la queue: $e');
        // Continuer vers la queue locale
      }
    }

    // Ajouter à la queue locale
    _pendingMessages.add(messageWithMeta);
    await _savePendingMessages();
    
    // Démarrer le timer de retry
    _startRetryTimer();
    
    print('Message ajouté à la queue hors ligne: ${_pendingMessages.length}');
    return false;
  }

  /// Démarre le timer de retry automatique
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _retryPendingMessages();
    });
  }

  /// Tente d'envoyer les messages en attente
  Future<void> _retryPendingMessages() async {
    if (_pendingMessages.isEmpty || !_isConnected || _chatWebSocket == null) {
      return;
    }

    print('Tentative d\'envoi de ${_pendingMessages.length} messages en attente');

    final messagesToSend = List<Map<String, dynamic>>.from(_pendingMessages);
    bool allSent = true;

    for (final message in messagesToSend) {
      try {
        // Préparer le message pour l'envoi (sans les métadonnées locales)
        final cleanMessage = Map<String, dynamic>.from(message);
        cleanMessage.remove('is_pending');
        cleanMessage.remove('local_id');

        _chatWebSocket!.sink.add(json.encode(cleanMessage));
        
        // Retirer de la queue si l'envoi réussit
        _pendingMessages.remove(message);
        
        print('Message envoyé avec succès: ${message['local_id']}');
      } catch (e) {
        print('Échec envoi message ${message['local_id']}: $e');
        allSent = false;
        // Continuer avec les autres messages
      }
    }

    await _savePendingMessages();

    if (allSent) {
      _retryTimer?.cancel();
      print('Tous les messages en attente ont été envoyés');
    }
  }

  /// Marque un message comme envoyé
  void markMessageAsSent(String localId) {
    _pendingMessages.removeWhere((msg) => msg['local_id'] == localId);
    _savePendingMessages();
  }

  /// Retourne la liste des messages en attente
  List<Map<String, dynamic>> get pendingMessages => List.unmodifiable(_pendingMessages);

  /// Retourne le nombre de messages en attente
  int get pendingCount => _pendingMessages.length;

  /// Vérifie si un message est en attente
  bool isMessagePending(String localId) {
    return _pendingMessages.any((msg) => msg['local_id'] == localId);
  }

  /// Nettoie les anciens messages en attente (plus de 24h)
  Future<void> cleanupOldMessages() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final initialCount = _pendingMessages.length;
    
    _pendingMessages.removeWhere((msg) {
      final timestamp = DateTime.parse(msg['timestamp']);
      return timestamp.isBefore(cutoff);
    });
    
    if (_pendingMessages.length != initialCount) {
      await _savePendingMessages();
      print('Nettoyage: ${initialCount - _pendingMessages.length} anciens messages supprimés');
    }
  }

  /// Déconnecte et nettoie
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _chatWebSocket?.sink.close();
    _chatWebSocket = null;
    _isConnected = false;
  }
}
