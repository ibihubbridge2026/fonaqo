import 'enums.dart';
import 'chat_message_v2.dart';

/// Modèle pour une conversation/chat room
class ChatRoom {
  final String id;
  final String? missionId; // Optionnel, lié à une mission
  final String name; // Nom de la conversation
  final String? avatar; // Avatar de la conversation
  final List<Participant> participants;
  final ChatMessageV2? lastMessage; // Dernier message
  final int unreadCount; // Nombre de messages non lus
  final bool isArchived;
  final bool isMuted;
  final DateTime updatedAt;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    this.missionId,
    required this.name,
    this.avatar,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    required this.updatedAt,
    required this.createdAt,
  });

  /// Vérifie si l'utilisateur est participant
  bool isParticipant(String userId) {
    return participants.any((p) => p.userId == userId);
  }

  /// Obtient l'autre participant (pour conversation 1-1)
  Participant? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission_id': missionId,
      'name': name,
      'avatar': avatar,
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_archived': isArchived,
      'is_muted': isMuted,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crée depuis JSON (format ConversationSerializer Django)
  factory ChatRoom.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final participants = <Participant>[];

    void addParticipant(Map<String, dynamic>? userMap, String role) {
      if (userMap == null) return;
      final id = userMap['id']?.toString() ?? '';
      final first = userMap['first_name']?.toString() ?? '';
      final last = userMap['last_name']?.toString() ?? '';
      final username = userMap['username']?.toString() ?? role;
      participants.add(Participant(
        userId: id,
        userName: '$first $last'.trim().isEmpty ? username : '$first $last'.trim(),
        avatar: userMap['avatar_url']?.toString(),
      ));
    }

    if (json['participants'] is List) {
      for (final p in json['participants'] as List) {
        participants.add(
          Participant.fromJson(Map<String, dynamic>.from(p as Map)),
        );
      }
    } else {
      addParticipant(
        json['client'] is Map ? Map<String, dynamic>.from(json['client'] as Map) : null,
        'client',
      );
      addParticipant(
        json['agent'] is Map ? Map<String, dynamic>.from(json['agent'] as Map) : null,
        'agent',
      );
    }

    final unreadClient = json['unread_count_client'] as int? ?? 0;
    final unreadAgent = json['unread_count_agent'] as int? ?? 0;
    final unread = json['unread_count'] as int? ??
        (currentUserId != null &&
                json['client'] is Map &&
                (json['client'] as Map)['id']?.toString() == currentUserId
            ? unreadClient
            : unreadAgent);

    return ChatRoom(
      id: json['id'].toString(),
      missionId: json['mission']?.toString() ?? json['mission_id']?.toString(),
      name: json['name']?.toString() ??
          json['mission_title']?.toString() ??
          'Conversation',
      avatar: json['avatar']?.toString(),
      participants: participants,
      lastMessage: json['last_message'] != null
          ? ChatMessageV2.fromJson(
              Map<String, dynamic>.from(json['last_message'] as Map),
            )
          : null,
      unreadCount: unread,
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Copie avec modifications
  ChatRoom copyWith({
    String? id,
    String? missionId,
    String? name,
    String? avatar,
    List<Participant>? participants,
    ChatMessageV2? lastMessage,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Participant à une conversation
class Participant {
  final String userId;
  final String userName;
  final String? avatar;
  final PresenceStatus presence;
  final DateTime? lastSeen;

  Participant({
    required this.userId,
    required this.userName,
    this.avatar,
    this.presence = PresenceStatus.offline,
    this.lastSeen,
  });

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'avatar': avatar,
      'presence': presence.toJson(),
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  /// Crée depuis JSON
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      avatar: json['avatar'] as String?,
      presence: PresenceStatusExtension.fromJson(
          json['presence'] as String? ?? 'offline'),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }

  /// Copie avec modifications
  Participant copyWith({
    String? userId,
    String? userName,
    String? avatar,
    PresenceStatus? presence,
    DateTime? lastSeen,
  }) {
    return Participant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      presence: presence ?? this.presence,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
