import 'package:fonaco/core/api/base_client.dart';
import 'package:fonaco/core/models/mission_model.dart';
import 'package:logger/logger.dart';

/// Repository pour les opérations de chat
class ChatRepository {
  final BaseClient _api = BaseClient();
  final Logger _logger = Logger();

  /// Récupère toutes les conversations de l'utilisateur
  Future<List<Map<String, dynamic>>> fetchMyConversations() async {
    try {
      final response = await _api.get('chat/conversations/my_conversations/');

      if (response.statusCode == 200) {
        final body = response.data;
        List<dynamic> data;
        if (body is List) {
          data = body;
        } else if (body is Map<String, dynamic>) {
          final inner = body['data'] ?? body['results'];
          data = inner is List ? inner : [];
        } else {
          data = [];
        }
        return data
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error fetching conversations: $e');
      return [];
    }
  }

  /// Crée ou récupère une conversation pour une mission
  Future<Map<String, dynamic>?> getOrCreateConversation(
      String missionId) async {
    try {
      final response = await _api.post(
        'chat/conversations/get_or_create/',
        data: {'mission_id': missionId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _unwrapConversation(response.data);
      }
      return null;
    } catch (e) {
      _logger.e('Error creating conversation: $e');
      return null;
    }
  }

  /// Récupère les messages d'une conversation
  Future<List<Map<String, dynamic>>> fetchConversationMessages(
      String conversationId) async {
    try {
      final response =
          await _api.get('chat/conversations/$conversationId/messages/');

      if (response.statusCode == 200) {
        final body = response.data;
        List<dynamic> data;
        if (body is List) {
          data = body;
        } else if (body is Map<String, dynamic>) {
          final inner = body['data'] ?? body['results'];
          data = inner is List ? inner : [];
        } else {
          data = [];
        }
        return data
            .map((item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      return [];
    }
  }

  /// Marquer des messages comme lus
  Future<bool> markMessagesAsRead(String conversationId,
      {List<String>? messageIds, bool markAll = false}) async {
    try {
      final body = {
        if (messageIds != null) 'message_ids': messageIds,
        'mark_all': markAll,
      };

      final response = await _api
          .post('chat/conversations/$conversationId/mark_read/', data: body);

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error marking messages as read: $e');
      return false;
    }
  }

  /// Envoyer un message
  Future<Map<String, dynamic>?> sendMessage(
      String conversationId, Map<String, dynamic> messageData) async {
    try {
      final response = await _api.post(
          'chat/conversations/$conversationId/send_message/',
          data: messageData);

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Error sending message: $e');
      return null;
    }
  }

  /// Mettre à jour le statut "en train d'écrire"
  Future<bool> updateTypingStatus(String conversationId, bool isTyping) async {
    try {
      final response = await _api
          .post('chat/conversations/$conversationId/typing_status/', data: {
        'is_typing': isTyping,
      });

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error updating typing status: $e');
      return false;
    }
  }

  /// Extrait les données conversation depuis une réponse API (avec ou sans enveloppe).
  static Map<String, dynamic>? _unwrapConversation(dynamic body) {
    if (body is! Map) return null;
    final map = body is Map<String, dynamic>
        ? body
        : Map<String, dynamic>.from(body);
    final inner = map['data'];
    if (inner is Map) {
      return inner is Map<String, dynamic>
          ? inner
          : Map<String, dynamic>.from(inner);
    }
    return map;
  }

  /// Archiver une conversation
  Future<bool> archiveConversation(String conversationId) async {
    try {
      final response = await _api
          .post('chat/conversations/$conversationId/archive/', data: {});

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error archiving conversation: $e');
      return false;
    }
  }
}
