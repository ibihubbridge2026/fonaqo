/// Modèle de données pour les Artisans (Annuaire/Vitrine Publicitaire)
/// Totalement indépendant des Agents Fonaqo (pas de compte utilisateur, pas de tracking GPS)
class ArtisanModel {
  final String id;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String specialty;
  final String biography;
  final int yearsOfExperience;
  final String city;
  final String district;
  final String phone;
  final String email;
  final double rating;
  final int completedMissions;
  final bool certified;
  final bool premium;
  final List<String> gallery;

  ArtisanModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.specialty,
    required this.biography,
    required this.yearsOfExperience,
    required this.city,
    required this.district,
    required this.phone,
    required this.email,
    required this.rating,
    required this.completedMissions,
    this.certified = false,
    this.premium = false,
    this.gallery = const [],
  });

  /// Nom complet de l'artisan
  String get fullName => '$firstName $lastName';

  /// Crée un ArtisanModel à partir d'un JSON
  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    return ArtisanModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? '',
      specialty: json['specialty'] ?? '',
      biography: json['biography'] ?? '',
      yearsOfExperience: json['years_of_experience'] ?? json['yearsOfExperience'] ?? 0,
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      rating: (json['rating'] ?? 4.0).toDouble(),
      completedMissions: json['completed_missions'] ?? json['completedMissions'] ?? 0,
      certified: json['certified'] ?? false,
      premium: json['premium'] ?? false,
      gallery: (json['gallery'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'specialty': specialty,
      'biography': biography,
      'years_of_experience': yearsOfExperience,
      'city': city,
      'district': district,
      'phone': phone,
      'email': email,
      'rating': rating,
      'completed_missions': completedMissions,
      'certified': certified,
      'premium': premium,
      'gallery': gallery,
    };
  }

  /// Copie avec modification sélective
  ArtisanModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? specialty,
    String? biography,
    int? yearsOfExperience,
    String? city,
    String? district,
    String? phone,
    String? email,
    double? rating,
    int? completedMissions,
    bool? certified,
    bool? premium,
    List<String>? gallery,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      specialty: specialty ?? this.specialty,
      biography: biography ?? this.biography,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      city: city ?? this.city,
      district: district ?? this.district,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      completedMissions: completedMissions ?? this.completedMissions,
      certified: certified ?? this.certified,
      premium: premium ?? this.premium,
      gallery: gallery ?? this.gallery,
    );
  }
}
