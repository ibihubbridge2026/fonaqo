/// Énumérations pour le système de chat

/// Type de message
enum MessageType {
  text,
  image,
  audio,
  file,
  video,
  location,
  contact,
}

/// Statut du message
enum MessageStatus {
  sending,      // En cours d'envoi
  sent,         // Envoyé au serveur
  delivered,    // Livré au destinataire
  read,         // Lu par le destinataire
  failed,       // Échec de l'envoi
}

/// Statut de présence
enum PresenceStatus {
  online,       // En ligne
  offline,      // Hors ligne
  away,         // Absent
  busy,         // Occupé
}

/// Extension pour convertir les enums en JSON
extension MessageTypeExtension on MessageType {
  String toJson() => toString().split('.').last;
  static MessageType fromJson(String value) {
    return MessageType.values.firstWhere(
      (e) => e.toJson() == value,
      orElse: () => MessageType.text,
    );
  }
}

extension MessageStatusExtension on MessageStatus {
  String toJson() => toString().split('.').last;
  static MessageStatus fromJson(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.toJson() == value,
      orElse: () => MessageStatus.sending,
    );
  }
}

extension PresenceStatusExtension on PresenceStatus {
  String toJson() => toString().split('.').last;
  static PresenceStatus fromJson(String value) {
    return PresenceStatus.values.firstWhere(
      (e) => e.toJson() == value,
      orElse: () => PresenceStatus.offline,
    );
  }
}
