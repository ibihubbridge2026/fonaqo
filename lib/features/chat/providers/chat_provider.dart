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
import 'package:fonaco/core/services/memory_auth_cache.dart';
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

  // ACK tracking : clientMsgId -> tempId local
  final Map<String, String> _pendingAcks = {};

  // Catchup deduplication : IDs déjà vus pour éviter doublons sur reconnexion
  final Set<String> _seenMessageIds = {};

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

  String? _currentUserId;

  /// Charge les conversations de l'utilisateur
  Future<void> loadConversations(BuildContext context) async {
    _isLoadingConversations = true;
    _error = null;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = auth.currentUser?.id;
    notifyListeners();

    try {
      // Hydrater le token depuis le stockage sécurisé avant l'appel API.
      await MemoryAuthCache().ensureLoaded();
      if (auth.accessToken == null) {
        await auth.refreshToken();
      }

      _loadConversationsFromCache();

      final conversationsData = await _repository.fetchMyConversations();
      _conversations = conversationsData
          .map((data) => ChatRoom.fromJson(data, currentUserId: _currentUserId))
          .toList();

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

  /// Sélectionne une conversation et connecte le WS mission-scoped.
  Future<void> selectConversation(
    ChatRoom conversation,
    BuildContext context, {
    String? missionId,
  }) async {
    _currentConversation = conversation;

    if (!_messages.containsKey(conversation.id)) {
      await loadMessages(conversation.id);
    }

    final effectiveMissionId = missionId ?? conversation.missionId;
    if (effectiveMissionId != null && effectiveMissionId.isNotEmpty) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.accessToken;
      if (token != null) {
        await _wsService.connect(
          missionId: effectiveMissionId,
          accessToken: token,
        );
      }
    }

    notifyListeners();
  }

  /// Envoie un message texte
  Future<void> sendTextMessage(String content, {String? senderId}) async {
    if (_currentConversation == null || content.trim().isEmpty) return;

    final effectiveSenderId = senderId ?? _currentUserId ?? '';
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessageV2.textMessage(
      id: tempId,
      conversationId: _currentConversation!.id,
      senderId: effectiveSenderId,
      content: content,
    );

    _addMessage(tempMessage);

    final clientMsgId = _wsService.sendMessage(content: content);
    _pendingAcks[clientMsgId] = tempId;

    if (!_wsService.isConnected) {
      final result = await _repository.sendMessage(
        _currentConversation!.id,
        {
          'content': content,
          'message_type': 'text',
          'client_message_id': clientMsgId,
        },
      );
      _updateMessageStatus(
        tempId,
        result != null ? MessageStatus.sent : MessageStatus.failed,
      );
    }
  }

  /// Envoie un message image, audio ou fichier.
  Future<void> sendMediaMessage({
    required MessageType type,
    required String content,
    String? fileName,
    int? fileSize,
    String? fileMimeType,
    int? duration,
    String? senderId,
  }) async {
    if (_currentConversation == null || content.isEmpty) return;

    final effectiveSenderId = senderId ?? _currentUserId ?? '';
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final convId = _currentConversation!.id;

    ChatMessageV2 tempMessage;
    switch (type) {
      case MessageType.image:
        tempMessage = ChatMessageV2.imageMessage(
          id: tempId,
          conversationId: convId,
          senderId: effectiveSenderId,
          imageUrl: content,
          fileName: fileName,
          fileSize: fileSize,
        );
        break;
      case MessageType.audio:
        tempMessage = ChatMessageV2.audioMessage(
          id: tempId,
          conversationId: convId,
          senderId: effectiveSenderId,
          audioUrl: content,
          fileName: fileName,
          duration: duration ?? 0,
          fileSize: fileSize,
        );
        break;
      case MessageType.file:
        tempMessage = ChatMessageV2.fileMessage(
          id: tempId,
          conversationId: convId,
          senderId: effectiveSenderId,
          fileUrl: content,
          fileName: fileName ?? 'fichier',
          fileSize: fileSize ?? 0,
          mimeType: fileMimeType ?? 'application/octet-stream',
        );
        break;
      default:
        return;
    }

    _addMessage(tempMessage);

    final result = await _repository.sendMessage(convId, {
      'content': content,
      'message_type': type.toJson(),
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (fileMimeType != null) 'file_mime_type': fileMimeType,
      if (duration != null) 'duration': duration,
    });
    _updateMessageStatus(
      tempId,
      result != null ? MessageStatus.sent : MessageStatus.failed,
    );
  }

  /// Envoie une proposition tarifaire (agent uniquement).
  Future<void> sendNegotiationProposal(
    double proposedPrice, {
    String? senderId,
  }) async {
    if (_currentConversation == null || proposedPrice <= 0) return;

    final effectiveSenderId = senderId ?? _currentUserId ?? '';
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessageV2.negotiationProposal(
      id: tempId,
      conversationId: _currentConversation!.id,
      senderId: effectiveSenderId,
      proposedPrice: proposedPrice,
    );
    _addMessage(tempMessage);

    final clientMsgId = _wsService.sendMessage(
      content: 'Proposition de tarif',
      messageType: MessageType.negotiationProposal.toJson(),
      proposedPrice: proposedPrice,
    );
    _pendingAcks[clientMsgId] = tempId;

    if (!_wsService.isConnected) {
      final result = await _repository.sendMessage(
        _currentConversation!.id,
        {
          'content': 'Proposition de tarif',
          'message_type': MessageType.negotiationProposal.toJson(),
          'proposed_price': proposedPrice,
          'client_message_id': clientMsgId,
        },
      );
      _updateMessageStatus(
        tempId,
        result != null ? MessageStatus.sent : MessageStatus.failed,
      );
    }
  }

  /// Met à jour le statut local d'une proposition tarifaire.
  void patchNegotiationStatus(String messageId, NegotiationStatus status) {
    if (_currentConversation == null) return;
    final convId = _currentConversation!.id;
    final msgs = _messages[convId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final meta = Map<String, dynamic>.from(msgs[idx].metadata ?? {});
    meta['negotiation_status'] = status.toApi();
    msgs[idx] = msgs[idx].copyWith(metadata: meta);
    notifyListeners();
  }

  /// Marque des messages comme lus
  Future<void> markAsRead(List<String> messageIds) async {
    if (_currentConversation == null) return;

    await _repository.markMessagesAsRead(
      _currentConversation!.id,
      messageIds: messageIds,
    );

    _wsService.markAsRead(messageIds, conversationOpen: true);

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
        _wsService.sendTypingStatus(false);
      });
      _wsService.sendTypingStatus(true);
    } else {
      _wsService.sendTypingStatus(false);
    }
  }

  /// Connecte au WebSocket pour une mission
  Future<void> connectWebSocket(
    BuildContext context, {
    required String missionId,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.accessToken;
    if (token == null) return;

    await _wsService.connect(missionId: missionId, accessToken: token);

    _wsSubscription ??= _wsService.events.listen(_handleWebSocketEvent);
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

      case 'message_ack':
        _handleMessageAck(event.data);
        break;

      case 'delivery_status':
        _handleDeliveryStatus(event.data);
        break;

      case 'catchup_result':
        _handleCatchupResult(event.data);
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

      case 'system_message':
        _handleSystemMessage(event.data);
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

    final raw = data['message'] as Map<String, dynamic>? ?? data;
    final message = ChatMessageV2.fromJson(raw);
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

    final userId = data['user_id']?.toString() ?? '';
    final isTyping = data['is_typing'] as bool? ?? data['typing'] as bool? ?? false;

    _typingUsers[userId] = isTyping;
    notifyListeners();
  }

  /// Gère l'ACK serveur après envoi d'un message
  void _handleMessageAck(Map<String, dynamic>? data) {
    if (data == null) return;
    final clientMsgId = data['client_message_id'] as String?;
    final serverId = data['message_id'] as String?;
    if (clientMsgId == null || serverId == null) return;

    final tempId = _pendingAcks.remove(clientMsgId);
    if (tempId != null) {
      // Remplacer l'ID temporaire par l'ID serveur
      for (final msgs in _messages.values) {
        final idx = msgs.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          msgs[idx] =
              msgs[idx].copyWith(id: serverId, status: MessageStatus.sent);
          notifyListeners();
          break;
        }
      }
    }
  }

  /// Gère un changement de statut de livraison (DELIVERED)
  void _handleDeliveryStatus(Map<String, dynamic>? data) {
    if (data == null) return;
    final messageId = data['message_id'] as String?;
    if (messageId == null) return;
    _updateMessageStatus(messageId, MessageStatus.delivered);
  }

  /// Gère les messages de rattrapage (reconnect)
  void _handleCatchupResult(Map<String, dynamic>? data) {
    if (data == null) return;
    final msgs = data['messages'] as List<dynamic>?;
    if (msgs == null) return;
    for (final raw in msgs) {
      final msg = ChatMessageV2.fromJson(raw as Map<String, dynamic>);
      // Déduplication globale avec _seenMessageIds pour éviter doublons sur reconnexions multiples
      if (!_seenMessageIds.contains(msg.id)) {
        _seenMessageIds.add(msg.id);
        final convMsgs = _messages[msg.conversationId] ?? [];
        if (!convMsgs.any((m) => m.id == msg.id)) {
          _addMessage(msg);
        }
      }
    }
  }

  /// Gère les messages système (changements de statut mission)
  void _handleSystemMessage(Map<String, dynamic>? data) {
    if (data == null) return;
    final raw = data['message'] as Map<String, dynamic>?;
    if (raw == null) return;
    _handleNewMessage(raw);
  }

  /// Gère un accusé de lecture
  void _handleReadReceipt(Map<String, dynamic>? data) {
    if (data == null) return;

    final messageIds = (data['message_ids'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    for (final messageId in messageIds) {
      _updateMessageStatus(messageId, MessageStatus.read);
    }
  }

  /// Gère un événement de présence
  void _handlePresenceEvent(Map<String, dynamic>? data) {
    if (data == null) return;

    final userId = data['user_id'] as String;
    final isOnline = data['is_online'] as bool? ?? false;
    final status = isOnline ? 'online' : 'offline';

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
    _seenMessageIds.add(message.id); // Marquer comme vu pour catchup futur
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
