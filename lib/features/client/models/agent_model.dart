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
    return AgentModel.fromApiMap(json);
  }

  /// Map renvoyé par `accounts/agents/nearby/` ou `suggestions/`.
  factory AgentModel.fromApiMap(Map<String, dynamic> json) {
    final fn = json['first_name']?.toString() ?? '';
    final ln = json['last_name']?.toString() ?? '';
    final composed = '$fn $ln'.trim();
    final name = (json['name']?.toString().trim().isNotEmpty == true)
        ? json['name'].toString()
        : (composed.isEmpty ? 'Agent' : composed);
    final tags = (json['expertise_tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .toList() ??
        const <String>[];
    final reliability = (json['reliability_score'] as num?)?.toDouble();
    final rating = (json['rating'] as num?)?.toDouble() ??
        (reliability != null ? (reliability / 20).clamp(1.0, 5.0) : 4.5);

    return AgentModel(
      id: json['id']?.toString() ?? '',
      name: name,
      avatarUrl: json['avatar_url']?.toString() ?? '',
      rating: rating,
      specialty: json['specialty']?.toString() ??
          (tags.isNotEmpty ? tags.first : 'Service général'),
      completedMissions: (json['completed_missions'] as num?)?.toInt() ?? 0,
      estimatedPrice: json['estimated_price']?.toString() ?? 'Sur devis',
      isTopChoice:
          json['is_top_choice'] == true || (reliability ?? 0) >= 90,
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
