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

  double? get proposedPrice {
    final meta = metadata?['proposed_price'];
    if (meta is num) return meta.toDouble();
    return double.tryParse(meta?.toString() ?? '');
  }

  NegotiationStatus get negotiationStatus =>
      NegotiationStatusExtension.fromApi(
        metadata?['negotiation_status']?.toString(),
      );

  bool get isNegotiationPending =>
      type == MessageType.negotiationProposal &&
      negotiationStatus == NegotiationStatus.pending;

  /// Proposition tarifaire envoyée par l'agent.
  factory ChatMessageV2.negotiationProposal({
    required String id,
    required String conversationId,
    required String senderId,
    required double proposedPrice,
    NegotiationStatus status = NegotiationStatus.pending,
    String? senderName,
  }) {
    return ChatMessageV2(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      type: MessageType.negotiationProposal,
      content: 'Proposition de tarif',
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      metadata: {
        'proposed_price': proposedPrice,
        'negotiation_status': status.toApi(),
      },
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

  /// Crée depuis JSON — compatible backend WS et API REST
  factory ChatMessageV2.fromJson(Map<String, dynamic> json) {
    // Accepte 'type' ou 'message_type'
    final typeStr = (json['type'] ?? json['message_type'] ?? 'text').toString();
    // Accepte 'status' ou 'delivery_status'
    final statusStr =
        (json['status'] ?? json['delivery_status'] ?? 'sent').toString();
    // Accepte 'conversation_id' ou 'conversation' (int from DRF)
    final convId =
        (json['conversation_id'] ?? json['conversation'] ?? '').toString();
    // sender_id peut être int ou String depuis le backend
    final senderIdRaw = json['sender_id'];
    final senderId = senderIdRaw?.toString() ?? '';

    return ChatMessageV2(
      id: json['id'].toString(),
      conversationId: convId,
      senderId: senderId,
      senderName: json['sender_name'] as String? ?? json['sender'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      type: MessageTypeExtension.fromJson(typeStr),
      content: json['content'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      fileMimeType: json['file_mime_type'] as String?,
      duration: (json['duration'] ?? json['audio_duration']) as int?,
      status: MessageStatusExtension.fromJson(statusStr),
      timestamp: DateTime.parse(
        (json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
            .toString(),
      ),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      metadata: _mergeNegotiationMetadata(json),
    );
  }

  static Map<String, dynamic>? _mergeNegotiationMetadata(
    Map<String, dynamic> json,
  ) {
    final base = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};
    if (json['proposed_price'] != null) {
      base['proposed_price'] = json['proposed_price'];
    }
    if (json['negotiation_status'] != null) {
      base['negotiation_status'] = json['negotiation_status'];
    }
    return base.isEmpty ? null : base;
  }

  /// Copie générique avec champs optionnels
  ChatMessageV2 copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    String? fileName,
    int? fileSize,
    String? fileMimeType,
    int? duration,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageV2(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileMimeType: fileMimeType ?? this.fileMimeType,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
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
