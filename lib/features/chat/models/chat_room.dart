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

  /// Crée depuis JSON
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      missionId: json['mission_id'] as String?,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] != null
          ? ChatMessageV2.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
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
