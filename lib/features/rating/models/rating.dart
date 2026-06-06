/// Modèle pour les évaluations (ratings)
class Rating {
  final String id;
  final String missionId;
  final String raterId; // ID de celui qui note
  final String raterName; // Nom de celui qui note
  final String? raterAvatar;
  final String ratedId; // ID de celui noté
  final String ratedName; // Nom de celui noté
  final String? ratedAvatar;
  final int score; // 1-5 étoiles
  final String? comment; // Commentaire optionnel
  final RatingType type; // client_to_agent ou agent_to_client
  final DateTime createdAt;
  final DateTime? updatedAt;

  Rating({
    required this.id,
    required this.missionId,
    required this.raterId,
    required this.raterName,
    this.raterAvatar,
    required this.ratedId,
    required this.ratedName,
    this.ratedAvatar,
    required this.score,
    this.comment,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  /// Crée depuis JSON
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      raterId: json['rater_id'] as String,
      raterName: json['rater_name'] as String,
      raterAvatar: json['rater_avatar'] as String?,
      ratedId: json['rated_id'] as String,
      ratedName: json['rated_name'] as String,
      ratedAvatar: json['rated_avatar'] as String?,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      type: RatingTypeExtension.fromJson(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission_id': missionId,
      'rater_id': raterId,
      'rater_name': raterName,
      'rater_avatar': raterAvatar,
      'rated_id': ratedId,
      'rated_name': ratedName,
      'rated_avatar': ratedAvatar,
      'score': score,
      'comment': comment,
      'type': type.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copie avec modifications
  Rating copyWith({
    String? id,
    String? missionId,
    String? raterId,
    String? raterName,
    String? raterAvatar,
    String? ratedId,
    String? ratedName,
    String? ratedAvatar,
    int? score,
    String? comment,
    RatingType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      raterId: raterId ?? this.raterId,
      raterName: raterName ?? this.raterName,
      raterAvatar: raterAvatar ?? this.raterAvatar,
      ratedId: ratedId ?? this.ratedId,
      ratedName: ratedName ?? this.ratedName,
      ratedAvatar: ratedAvatar ?? this.ratedAvatar,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Type de notation
enum RatingType {
  clientToAgent,
  agentToClient,
}

extension RatingTypeExtension on RatingType {
  String toJson() => toString().split('.').last;

  static RatingType fromJson(String value) {
    switch (value) {
      case 'client_to_agent':
        return RatingType.clientToAgent;
      case 'agent_to_client':
        return RatingType.agentToClient;
      default:
        return RatingType.clientToAgent;
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
