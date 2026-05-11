/// Modèle utilisateur pour l'application FONACO
/// Reflète la structure du backend Django
class UserModel {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String role; // 'agent' ou 'client' - avec valeur par défaut 'client'
  final bool isVerified;
  final String? avatarUrl;
  final AgentProfile? agentProfile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    required this.role,
    required this.isVerified,
    this.avatarUrl,
    this.agentProfile,
    this.createdAt,
    this.updatedAt,
  });

  /// Crée un UserModel à partir d'un JSON (réponse API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      role: json['role']?.toString() ?? 'client',
      isVerified: json['is_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url']?.toString(),
      agentProfile: json['agent_profile'] != null
          ? AgentProfile.fromJson(json['agent_profile'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convertit le UserModel en JSON (requête API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'role': role,
      'is_verified': isVerified,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (agentProfile != null) 'agent_profile': agentProfile!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Crée une copie du UserModel avec des champs modifiés
  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? role,
    bool? isVerified,
    String? avatarUrl,
    AgentProfile? agentProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      agentProfile: agentProfile ?? this.agentProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retourne le nom complet de l'utilisateur
  String? get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email;
  }

  /// Retourne true si l'utilisateur est un agent
  bool get isAgent => role == 'agent';

  /// Retourne true si l'utilisateur est un client
  bool get isClient => role == 'client';

  /// Retourne true si l'utilisateur est un agent avec un profil complet
  bool get isCompleteAgent => isAgent && agentProfile != null;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.role == role &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        role.hashCode ^
        isVerified.hashCode;
  }
}

/// Profil spécifique pour les agents FONACO
class AgentProfile {
  final String? bio;
  final List<String> skills;
  final double rating;
  final int totalMissions;
  final bool isAvailable;
  final String? location;
  final List<String> certifications;
  final double? hourlyRate;
  final DateTime? lastActive;

  const AgentProfile({
    this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.totalMissions = 0,
    this.isAvailable = false,
    this.location,
    this.certifications = const [],
    this.hourlyRate,
    this.lastActive,
  });

  /// Crée un AgentProfile à partir d'un JSON
  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    return AgentProfile(
      bio: json['bio']?.toString(),
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((skill) => skill.toString())
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalMissions: json['total_missions'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      location: json['location']?.toString(),
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map((cert) => cert.toString())
              .toList() ??
          [],
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'].toString())
          : null,
    );
  }

  /// Convertit l'AgentProfile en JSON
  Map<String, dynamic> toJson() {
    return {
      if (bio != null) 'bio': bio,
      'skills': skills,
      'rating': rating,
      'total_missions': totalMissions,
      'is_available': isAvailable,
      if (location != null) 'location': location,
      'certifications': certifications,
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
      if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
    };
  }

  /// Crée une copie de l'AgentProfile avec des champs modifiés
  AgentProfile copyWith({
    String? bio,
    List<String>? skills,
    double? rating,
    int? totalMissions,
    bool? isAvailable,
    String? location,
    List<String>? certifications,
    double? hourlyRate,
    DateTime? lastActive,
  }) {
    return AgentProfile(
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalMissions: totalMissions ?? this.totalMissions,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Retourne true si l'agent est actuellement actif
  bool get isActive =>
      isAvailable &&
      (lastActive != null
          ? DateTime.now().difference(lastActive!).inDays < 7
          : false);

  /// Retourne la note formatée en étoiles
  String get formattedRating => rating.toStringAsFixed(1);

  @override
  String toString() {
    return 'AgentProfile(rating: $rating, missions: $totalMissions, available: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentProfile &&
        other.bio == bio &&
        other.skills == skills &&
        other.rating == rating &&
        other.totalMissions == totalMissions &&
        other.isAvailable == isAvailable &&
        other.location == location &&
        other.certifications == certifications &&
        other.hourlyRate == hourlyRate;
  }

  @override
  int get hashCode {
    return bio.hashCode ^
        skills.hashCode ^
        rating.hashCode ^
        totalMissions.hashCode ^
        isAvailable.hashCode ^
        location.hashCode ^
        certifications.hashCode ^
        hourlyRate.hashCode;
  }
}
