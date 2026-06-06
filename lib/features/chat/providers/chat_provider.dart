import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fonaco/features/chat/models/chat_message_v2.dart';
import 'package:fonaco/features/chat/models/chat_room.dart';
import 'package:fonaco/features/chat/models/enums.dart';
import 'package:fonaco/features/chat/services/websocket_service.dart';
import 'package:fonaco/features/chat/chat_repository.dart';
import 'package:fonaco/core/services/cache_service.dart';
import 'package:fonaco/core/utils/app_logger.dart';
import 'package:fonaco/core/providers/auth_provider.dart';

/// Provider pour la gestion du chat
/// Gère l'état des conversations, messages et connexion WebSocket
class ChatProvider with ChangeNotifier {
  final ChatRepository _repository = ChatRepository();
  final CacheService _cacheService = CacheService();
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final AppLogger _logger = AppLogger();

  // État
  List<ChatRoom> _conversations = [];
  Map<String, List<ChatMessageV2>> _messages = {}; // conversationId -> messages
  ChatRoom? _currentConversation;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  String? _error;
  bool _isConnected = false;

  // Typing indicator
  Map<String, bool> _typingUsers = {}; // userId -> isTyping
  Timer? _typingDebounceTimer;

  // Pagination
  Map<String, int> _currentPage = {}; // conversationId -> page
  Map<String, bool> _hasMore = {}; // conversationId -> hasMore
  static const int _pageSize = 20;

  // Stream subscription
  StreamSubscription? _wsSubscription;

  // Getters
  List<ChatRoom> get conversations => _conversations;
  List<ChatMessageV2> get currentMessages => _currentConversation != null
      ? _messages[_currentConversation!.id] ?? []
      : [];
  ChatRoom? get currentConversation => _currentConversation;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  bool get isConnected => _isConnected;
  Map<String, bool> get typingUsers => _typingUsers;

  /// Charge les conversations de l'utilisateur
  Future<void> loadConversations(BuildContext context) async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      // Charger depuis le cache d'abord
      _loadConversationsFromCache();

      // Charger depuis l'API
      final conversationsData = await _repository.fetchMyConversations();
      _conversations =
          conversationsData.map((data) => ChatRoom.fromJson(data)).toList();

      // Mettre à jour le cache
      await _cacheConversations();

      _logger.i('Loaded ${_conversations.length} conversations');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error loading conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Charge les messages d'une conversation
  Future<void> loadMessages(String conversationId,
      {bool refresh = false}) async {
    if (refresh) {
      _currentPage[conversationId] = 1;
      _hasMore[conversationId] = true;
    }

    final page = _currentPage[conversationId] ?? 1;
    _isLoadingMessages = true;
    notifyListeners();

    try {
      // Charger depuis le cache d'abord
      if (!refresh) {
        _loadMessagesFromCache(conversationId);
      }

      // Charger depuis l'API
      final messagesData = await _repository.fetchConversationMessages(
        conversationId,
      );

      final messages =
          messagesData.map((data) => ChatMessageV2.fromJson(data)).toList();

      if (refresh || !_messages.containsKey(conversationId)) {
        _messages[conversationId] = messages;
      } else {
        _messages[conversationId]!.addAll(messages);
      }

      // Mettre à jour la pagination
      _currentPage[conversationId] = page + 1;
      _hasMore[conversationId] = messages.length >= _pageSize;

      // Mettre à jour le cache
      await _cacheMessages(conversationId);

      _logger.i('Loaded ${messages.length} messages for $conversationId');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error loading messages: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Charge plus de messages (pagination)
  Future<void> loadMoreMessages(String conversationId) async {
    if (_isLoadingMessages || !(_hasMore[conversationId] ?? true)) return;

    await loadMessages(conversationId);
  }

  /// Sélectionne une conversation
  void selectConversation(ChatRoom conversation) {
    _currentConversation = conversation;

    // Charger les messages si pas déjà chargés
    if (!_messages.containsKey(conversation.id)) {
      loadMessages(conversation.id);
    }

    // Joindre la conversation via WebSocket
    _wsService.joinConversation(conversation.id);

    notifyListeners();
  }

  /// Envoie un message texte
  Future<void> sendTextMessage(String content) async {
    if (_currentConversation == null || content.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessageV2.textMessage(
      id: tempId,
      conversationId: _currentConversation!.id,
      senderId: 'current_user', // TODO: Get from AuthProvider
      content: content,
    );

    // Ajouter le message temporaire
    _addMessage(tempMessage);

    // Envoyer via WebSocket
    _wsService.sendMessage(
      conversationId: _currentConversation!.id,
      content: content,
      messageType: 'text',
    );

    // Envoyer via API pour persistance
    final result = await _repository.sendMessage(
      _currentConversation!.id,
      tempMessage.toJson(),
    );

    if (result != null) {
      // Mettre à jour avec l'ID réel
      _updateMessageStatus(tempId, MessageStatus.sent);
    } else {
      _updateMessageStatus(tempId, MessageStatus.failed);
    }
  }

  /// Marque des messages comme lus
  Future<void> markAsRead(List<String> messageIds) async {
    if (_currentConversation == null) return;

    await _repository.markMessagesAsRead(
      _currentConversation!.id,
      messageIds: messageIds,
    );

    // Envoyer via WebSocket
    _wsService.markAsRead(_currentConversation!.id, messageIds);

    // Mettre à jour localement
    for (final messageId in messageIds) {
      final message = _messages[_currentConversation!.id]
          ?.firstWhere((m) => m.id == messageId);
      if (message != null) {
        _updateMessageStatus(messageId, MessageStatus.read);
      }
    }
  }

  /// Met à jour le statut de typing avec debounce
  void updateTypingStatus(bool isTyping) {
    if (_currentConversation == null) return;

    _typingDebounceTimer?.cancel();

    if (isTyping) {
      _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
        _wsService.sendTypingStatus(_currentConversation!.id, false);
      });
      _wsService.sendTypingStatus(_currentConversation!.id, true);
    } else {
      _wsService.sendTypingStatus(_currentConversation!.id, false);
    }
  }

  /// Connecte au WebSocket
  Future<void> connectWebSocket(BuildContext context) async {
    await _wsService.connect(context);

    _wsSubscription = _wsService.events.listen((event) {
      _handleWebSocketEvent(event);
    });
  }

  /// Déconnecte du WebSocket
  void disconnectWebSocket() {
    _wsService.disconnect();
    _wsSubscription?.cancel();
    _isConnected = false;
    notifyListeners();
  }

  /// Gère les événements WebSocket
  void _handleWebSocketEvent(ChatEvent event) {
    switch (event.type) {
      case 'connected':
        _isConnected = true;
        notifyListeners();
        _logger.i('WebSocket connected');
        break;

      case 'message':
        _handleNewMessage(event.data);
        break;

      case 'typing':
        _handleTypingEvent(event.data);
        break;

      case 'read_receipt':
        _handleReadReceipt(event.data);
        break;

      case 'presence':
        _handlePresenceEvent(event.data);
        break;

      case 'reconnecting':
        _logger.i('WebSocket reconnecting...');
        break;

      case 'reconnect_failed':
        _isConnected = false;
        notifyListeners();
        _logger.e('WebSocket reconnection failed');
        break;
    }
  }

  /// Gère un nouveau message reçu
  void _handleNewMessage(Map<String, dynamic>? data) {
    if (data == null) return;

    final message = ChatMessageV2.fromJson(data);
    _addMessage(message);

    // Mettre à jour le lastMessage de la conversation
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (conversationIndex != -1) {
      _conversations[conversationIndex] =
          _conversations[conversationIndex].copyWith(lastMessage: message);
      notifyListeners();
    }
  }

  /// Gère un événement de typing
  void _handleTypingEvent(Map<String, dynamic>? data) {
    if (data == null) return;

    final userId = data['user_id'] as String;
    final isTyping = data['is_typing'] as bool;

    _typingUsers[userId] = isTyping;
    notifyListeners();
  }

  /// Gère un accusé de lecture
  void _handleReadReceipt(Map<String, dynamic>? data) {
    if (data == null) return;

    final messageIds = data['message_ids'] as List<String>;
    for (final messageId in messageIds) {
      _updateMessageStatus(messageId, MessageStatus.read);
    }
  }

  /// Gère un événement de présence
  void _handlePresenceEvent(Map<String, dynamic>? data) {
    if (data == null) return;

    final userId = data['user_id'] as String;
    final status = data['status'] as String;

    // Mettre à jour la présence dans les conversations
    for (final conversation in _conversations) {
      final participantIndex =
          conversation.participants.indexWhere((p) => p.userId == userId);
      if (participantIndex != -1) {
        conversation.participants[participantIndex] =
            conversation.participants[participantIndex].copyWith(
          presence: PresenceStatusExtension.fromJson(status),
          lastSeen: data['last_seen'] != null
              ? DateTime.parse(data['last_seen'] as String)
              : null,
        );
      }
    }

    notifyListeners();
  }

  /// Ajoute un message à la conversation
  void _addMessage(ChatMessageV2 message) {
    final conversationId = message.conversationId;
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);
    notifyListeners();
  }

  /// Met à jour le statut d'un message
  void _updateMessageStatus(String messageId, MessageStatus status) {
    for (final messages in _messages.values) {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWithStatus(status);
        notifyListeners();
        break;
      }
    }
  }

  /// Charge les conversations depuis le cache
  void _loadConversationsFromCache() {
    try {
      final cached = _cacheService.getCachedJsonResponse('chat_conversations');
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        _conversations = data
            .map((item) => ChatRoom.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _logger.w('Error loading conversations from cache: $e');
    }
  }

  /// Cache les conversations
  Future<void> _cacheConversations() async {
    try {
      await _cacheService.cacheJsonResponse(
        'chat_conversations',
        jsonEncode(_conversations.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      _logger.w('Error caching conversations: $e');
    }
  }

  /// Charge les messages depuis le cache
  void _loadMessagesFromCache(String conversationId) {
    try {
      final cached =
          _cacheService.getCachedJsonResponse('chat_messages_$conversationId');
      if (cached != null) {
        final data = jsonDecode(cached) as List;
        _messages[conversationId] = data
            .map((item) => ChatMessageV2.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _logger.w('Error loading messages from cache: $e');
    }
  }

  /// Cache les messages
  Future<void> _cacheMessages(String conversationId) async {
    try {
      await _cacheService.cacheJsonResponse(
        'chat_messages_$conversationId',
        jsonEncode(_messages[conversationId]?.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _logger.w('Error caching messages: $e');
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _typingDebounceTimer?.cancel();
    _wsService.dispose();
    super.dispose();
  }
}
