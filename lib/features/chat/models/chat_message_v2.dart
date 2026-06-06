import 'enums.dart';

/// Modèle enrichi pour un message de chat
class ChatMessageV2 {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final MessageType type;
  final String? content; // Texte pour text, URL pour image/file/audio
  final String? fileName; // Nom du fichier pour file/audio
  final int? fileSize; // Taille en octets
  final String? fileMimeType; // MIME type du fichier
  final int? duration; // Durée en secondes pour audio/video
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDeleted;
  final Map<String, dynamic>?
      metadata; // Données supplémentaires (location, contact, etc.)

  ChatMessageV2({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    this.content,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    this.duration,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.deliveredAt,
    this.readAt,
    this.isDeleted = false,
    this.metadata,
  });

  /// Crée un message texte envoyé par l'utilisateur
  factory ChatMessageV2.textMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.text,
      content: content,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
  }

  /// Crée un message image
  factory ChatMessageV2.imageMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String imageUrl,
    String? fileName,
    int? fileSize,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.image,
      content: imageUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileMimeType: 'image/jpeg',
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
  }

  /// Crée un message audio
  factory ChatMessageV2.audioMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String audioUrl,
    required int duration,
    String? fileName,
    int? fileSize,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.audio,
      content: audioUrl,
      fileName: fileName,
      fileSize: fileSize,
      duration: duration,
      fileMimeType: 'audio/mpeg',
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
  }

  /// Crée un message fichier
  factory ChatMessageV2.fileMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required String mimeType,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: MessageType.file,
      content: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileMimeType: mimeType,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'type': type.toJson(),
      'content': content,
      'file_name': fileName,
      'file_size': fileSize,
      'file_mime_type': fileMimeType,
      'duration': duration,
      'status': status.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'metadata': metadata,
    };
  }

  /// Crée depuis JSON
  factory ChatMessageV2.fromJson(Map<String, dynamic> json) {
    return ChatMessageV2(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      type: MessageTypeExtension.fromJson(json['type'] as String),
      content: json['content'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileMimeType: json['file_mime_type'] as String?,
      duration: json['duration'] as int?,
      status: MessageStatusExtension.fromJson(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Copie avec modification de statut
  ChatMessageV2 copyWithStatus(MessageStatus newStatus) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      fileName: fileName,
      fileSize: fileSize,
      fileMimeType: fileMimeType,
      duration: duration,
      status: newStatus,
      timestamp: timestamp,
      deliveredAt:
          newStatus == MessageStatus.delivered ? DateTime.now() : deliveredAt,
      readAt: newStatus == MessageStatus.read ? DateTime.now() : readAt,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageV2 && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
