/// Modèle unifié pour un message dans une conversation
class ChatMessage {
  final String id;
  final String text;
  final String time;
  final bool isMe;
  final String? senderId;
  final String? senderName;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
    this.senderId,
    this.senderName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Crée un message envoyé par l'utilisateur actuel
  factory ChatMessage.fromUser({
    required String text,
    required String chatId,
    String? senderId,
    String? senderName,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${chatId}_${now.millisecondsSinceEpoch}',
      text: text,
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      isMe: true,
      senderId: senderId,
      senderName: senderName,
      timestamp: now,
    );
  }

  /// Crée un message reçu d'un autre utilisateur
  factory ChatMessage.fromOther({
    required String text,
    required String time,
    required String senderId,
    String? senderName,
    String? messageId,
  }) {
    return ChatMessage(
      id: messageId ??
          'msg_${senderId}_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      time: time,
      isMe: false,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Convertit le message en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'time': time,
      'isMe': isMe,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Crée un message à partir d'une Map
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      time: json['time'] as String,
      isMe: json['isMe'] as bool,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, isMe: $isMe, time: $time)';
  }
}
