/// Modèle pour les boosts (missions mises en avant)
class Boost {
  final String id;
  final String missionId;
  final String? missionTitle;
  final String? missionImage;
  final String userId;
  final String userName;
  final DateTime startedAt;
  final DateTime expiresAt;
  final BoostStatus status;
  final int durationHours;
  final double amountPaid;
  final DateTime createdAt;

  Boost({
    required this.id,
    required this.missionId,
    this.missionTitle,
    this.missionImage,
    required this.userId,
    required this.userName,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    required this.durationHours,
    required this.amountPaid,
    required this.createdAt,
  });

  /// Crée depuis JSON
  factory Boost.fromJson(Map<String, dynamic> json) {
    return Boost(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      missionTitle: json['mission_title'] as String?,
      missionImage: json['mission_image'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: BoostStatusExtension.fromJson(json['status'] as String),
      durationHours: json['duration_hours'] as int,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission_id': missionId,
      'mission_title': missionTitle,
      'mission_image': missionImage,
      'user_id': userId,
      'user_name': userName,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status.toJson(),
      'duration_hours': durationHours,
      'amount_paid': amountPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Vérifie si le boost est actif
  bool get isActive {
    final now = DateTime.now();
    return status == BoostStatus.active && now.isBefore(expiresAt);
  }

  /// Vérifie si le boost est expiré
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(expiresAt);
  }

  /// Temps restant en heures
  int get remainingHours {
    final now = DateTime.now();
    if (isExpired) return 0;
    return expiresAt.difference(now).inHours;
  }

  /// Pourcentage de temps écoulé
  double get progressPercentage {
    final totalDuration = expiresAt.difference(startedAt).inHours;
    final elapsed = DateTime.now().difference(startedAt).inHours;
    if (totalDuration == 0) return 0;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}

/// Statut du boost
enum BoostStatus {
  pending, // En attente de paiement
  active, // Actif
  expired, // Expiré
  cancelled, // Annulé
}

extension BoostStatusExtension on BoostStatus {
  String toJson() => toString().split('.').last;

  static BoostStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return BoostStatus.pending;
      case 'active':
        return BoostStatus.active;
      case 'expired':
        return BoostStatus.expired;
      case 'cancelled':
        return BoostStatus.cancelled;
      default:
        return BoostStatus.pending;
    }
  }
}

/// Options de boost disponibles
class BoostOption {
  final int durationHours;
  final double price;
  final String description;

  BoostOption({
    required this.durationHours,
    required this.price,
    required this.description,
  });

  /// Options par défaut
  static List<BoostOption> getDefaultOptions() {
    return [
      BoostOption(
        durationHours: 1,
        price: 500,
        description: '1 heure de visibilité',
      ),
      BoostOption(
        durationHours: 6,
        price: 2000,
        description: '6 heures de visibilité',
      ),
      BoostOption(
        durationHours: 24,
        price: 5000,
        description: '24 heures de visibilité',
      ),
      BoostOption(
        durationHours: 72,
        price: 10000,
        description: '3 jours de visibilité',
      ),
    ];
  }
}
