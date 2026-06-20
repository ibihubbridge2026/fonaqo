/// Modèle pour les évaluations (ratings)
class Rating {
  final String id;
  final String missionId;
  final String reviewerId; // ID de celui qui note (backend: reviewer)
  final String reviewerName; // Nom de celui qui note
  final String? reviewerAvatar;
  final String revieweeId; // ID de celui noté (backend: reviewee)
  final String revieweeName; // Nom de celui noté
  final String? revieweeAvatar;
  final int score; // 1-5 étoiles
  final String? comment; // Commentaire optionnel
  final RatingType ratingType; // CLIENT_RATES_AGENT ou AGENT_RATES_CLIENT
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.missionId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.revieweeId,
    required this.revieweeName,
    this.revieweeAvatar,
    required this.score,
    this.comment,
    required this.ratingType,
    required this.createdAt,
  });

  /// Crée depuis JSON (backend Django format)
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      missionId: json['mission'] as String,
      reviewerId: json['reviewer'] as String,
      reviewerName: json['reviewer_name'] ?? 'Utilisateur',
      reviewerAvatar: json['reviewer_avatar'] as String?,
      revieweeId: json['reviewee'] as String,
      revieweeName: json['reviewee_name'] ?? 'Utilisateur',
      revieweeAvatar: json['reviewee_avatar'] as String?,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      ratingType: RatingTypeExtension.fromJson(json['rating_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission': missionId,
      'reviewer': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_avatar': reviewerAvatar,
      'reviewee': revieweeId,
      'reviewee_name': revieweeName,
      'reviewee_avatar': revieweeAvatar,
      'score': score,
      'comment': comment,
      'rating_type': ratingType.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Rating copyWith({
    String? id,
    String? missionId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    String? revieweeId,
    String? revieweeName,
    String? revieweeAvatar,
    int? score,
    String? comment,
    RatingType? ratingType,
    DateTime? createdAt,
  }) {
    return Rating(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      revieweeId: revieweeId ?? this.revieweeId,
      revieweeName: revieweeName ?? this.revieweeName,
      revieweeAvatar: revieweeAvatar ?? this.revieweeAvatar,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      ratingType: ratingType ?? this.ratingType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Type de notation (backend Django enum)
enum RatingType {
  clientRatesAgent, // CLIENT_RATES_AGENT
  agentRatesClient, // AGENT_RATES_CLIENT
}

extension RatingTypeExtension on RatingType {
  String toJson() {
    switch (this) {
      case RatingType.clientRatesAgent:
        return 'CLIENT_RATES_AGENT';
      case RatingType.agentRatesClient:
        return 'AGENT_RATES_CLIENT';
    }
  }

  static RatingType fromJson(String value) {
    switch (value) {
      case 'CLIENT_RATES_AGENT':
        return RatingType.clientRatesAgent;
      case 'AGENT_RATES_CLIENT':
        return RatingType.agentRatesClient;
      default:
        return RatingType.clientRatesAgent;
    }
  }
}

/// Statistiques de notation pour un utilisateur
class RatingStats {
  final String userId;
  final double averageScore; // Moyenne 1-5
  final int totalRatings; // Nombre total de notes
  final int fiveStarCount; // Nombre de 5 étoiles
  final int fourStarCount; // Nombre de 4 étoiles
  final int threeStarCount; // Nombre de 3 étoiles
  final int twoStarCount; // Nombre de 2 étoiles
  final int oneStarCount; // Nombre de 1 étoile

  RatingStats({
    required this.userId,
    required this.averageScore,
    required this.totalRatings,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  /// Crée depuis JSON
  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      userId: json['user_id'] as String,
      averageScore: (json['average_score'] as num).toDouble(),
      totalRatings: json['total_ratings'] as int,
      fiveStarCount: json['five_star_count'] as int,
      fourStarCount: json['four_star_count'] as int,
      threeStarCount: json['three_star_count'] as int,
      twoStarCount: json['two_star_count'] as int,
      oneStarCount: json['one_star_count'] as int,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'average_score': averageScore,
      'total_ratings': totalRatings,
      'five_star_count': fiveStarCount,
      'four_star_count': fourStarCount,
      'three_star_count': threeStarCount,
      'two_star_count': twoStarCount,
      'one_star_count': oneStarCount,
    };
  }

  /// Pourcentage de 5 étoiles
  double get fiveStarPercentage {
    if (totalRatings == 0) return 0;
    return fiveStarCount / totalRatings * 100;
  }

  /// Pourcentage de 4 étoiles
  double get fourStarPercentage {
    if (totalRatings == 0) return 0;
    return fourStarCount / totalRatings * 100;
  }

  /// Pourcentage de 3 étoiles
  double get threeStarPercentage {
    if (totalRatings == 0) return 0;
    return threeStarCount / totalRatings * 100;
  }

  /// Pourcentage de 2 étoiles
  double get twoStarPercentage {
    if (totalRatings == 0) return 0;
    return twoStarCount / totalRatings * 100;
  }

  /// Pourcentage de 1 étoile
  double get oneStarPercentage {
    if (totalRatings == 0) return 0;
    return oneStarCount / totalRatings * 100;
  }
}
