class AgentModel {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;
  final String specialty;
  final int completedMissions;
  final String estimatedPrice;
  final bool isTopChoice;
  final String? city;
  final String? district;
  final String? address;

  AgentModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.specialty,
    required this.completedMissions,
    required this.estimatedPrice,
    this.isTopChoice = false,
    this.city,
    this.district,
    this.address,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Agent',
      avatarUrl: json['avatar_url'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      specialty: json['specialty'] ?? 'Service général',
      completedMissions: json['completed_missions'] ?? 0,
      estimatedPrice: json['estimated_price'] ?? '0 FCFA',
      isTopChoice: json['is_top_choice'] ?? false,
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'rating': rating,
      'specialty': specialty,
      'completed_missions': completedMissions,
      'estimated_price': estimatedPrice,
      'is_top_choice': isTopChoice,
      'city': city,
      'district': district,
      'address': address,
    };
  }
}
