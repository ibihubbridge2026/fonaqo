/// Énumérations pour le système de chat

/// Type de message chat.
///
/// Backend Django (`message_type`) :
/// - `text`, `image`, `voice`, `file`, `system`, `negotiation`
///
/// Négociation (`negotiation`) :
/// - `proposed_price` : montant FCFA proposé par l'agent
/// - `negotiation_status` : `PENDING` | `ACCEPTED` | `REJECTED`
enum MessageType {
  text,
  image,
  audio,
  file,
  video,
  location,
  contact,
  /// Proposition tarifaire agent → client (`negotiation` côté API).
  negotiationProposal,
}

/// Statut d'une proposition tarifaire dans le chat.
enum NegotiationStatus {
  pending,
  accepted,
  rejected,
}

/// Statut du message
enum MessageStatus {
  sending, // En cours d'envoi
  sent, // Envoyé au serveur
  delivered, // Livré au destinataire
  read, // Lu par le destinataire
  failed, // Échec de l'envoi
}

/// Statut de présence
enum PresenceStatus {
  online, // En ligne
  offline, // Hors ligne
  away, // Absent
  busy, // Occupé
}

/// Extension pour convertir les enums en JSON
extension MessageTypeExtension on MessageType {
  String toJson() {
    switch (this) {
      case MessageType.negotiationProposal:
        return 'negotiation';
      case MessageType.audio:
        return 'voice';
      default:
        return toString().split('.').last;
    }
  }

  static MessageType fromJson(String value) {
    switch (value) {
      case 'negotiation':
      case 'NEGOTIATION':
      case 'NEGOTIATION_PROPOSAL':
        return MessageType.negotiationProposal;
      case 'voice':
        return MessageType.audio;
      default:
        return MessageType.values.firstWhere(
          (e) => e.toJson() == value,
          orElse: () => MessageType.text,
        );
    }
  }
}

extension NegotiationStatusExtension on NegotiationStatus {
  String toApi() => name.toUpperCase();

  static NegotiationStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACCEPTED':
        return NegotiationStatus.accepted;
      case 'REJECTED':
        return NegotiationStatus.rejected;
      default:
        return NegotiationStatus.pending;
    }
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
