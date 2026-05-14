/// Modèle de mission pour l'application FONACO
/// Reflète la structure du backend Django (UUID + coordonnées plates).
class MissionModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final MissionStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? clientName;
  final String? agentName;
  final String? address;
  final String? category;
  final String? avatarUrl;
  final bool isVerified;
  final bool isConfidential;
  final bool isUrgent;
  final List<String>? tags;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.clientName,
    this.agentName,
    this.address,
    this.category,
    this.avatarUrl,
    this.isVerified = false,
    this.isConfidential = false,
    this.isUrgent = false,
    this.tags,
  });

  /// Crée un MissionModel à partir d'un JSON (réponse API).
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _readDouble(json['price']) ?? 0.0,
      status: parseMissionStatus(json['status']?.toString()),
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      clientName: json['client_name']?.toString(),
      agentName: json['agent_name']?.toString(),
      address: json['address']?.toString(),
      category: json['category']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      isConfidential: json['is_confidential'] as bool? ?? false,
      isUrgent: json['is_urgent'] as bool? ?? false,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
    );
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Convertit le MissionModel en JSON (requête API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'status': status.name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (clientName != null) 'client_name': clientName,
      if (agentName != null) 'agent_name': agentName,
      if (address != null) 'address': address,
      if (category != null) 'category': category,
    };
  }

  /// Parse le statut depuis l'API Django (TextChoices).
  static MissionStatus parseMissionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return MissionStatus.PENDING;
      case 'accepted':
        return MissionStatus.ACCEPTED;
      case 'on_the_way':
        return MissionStatus.ON_THE_WAY;
      case 'arrived':
        return MissionStatus.ARRIVED;
      case 'in_progress':
        return MissionStatus.IN_PROGRESS;
      case 'completed':
        return MissionStatus.COMPLETED;
      case 'cancelled':
        return MissionStatus.CANCELLED;
      case 'disputed':
        return MissionStatus.DISPUTED;
      default:
        return MissionStatus.PENDING;
    }
  }

  /// Crée une copie du MissionModel avec des champs modifiés.
  MissionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    MissionStatus? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
    String? agentName,
    String? address,
    String? category,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
      agentName: agentName ?? this.agentName,
      address: address ?? this.address,
      category: category ?? this.category,
    );
  }

  /// Retourne le statut formaté pour l'affichage.
  String get formattedStatus => status.label;

  /// Alias pour l'affichage du statut dans les cartes.
  String get statusDisplay => status.label;

  /// Retourne un texte relatif approximatif depuis createdAt.
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  @override
  String toString() {
    return 'MissionModel(id: $id, title: $title, status: $status, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.price == price &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        price.hashCode ^
        status.hashCode;
  }
}

/// Énumération des statuts de mission.
enum MissionStatus {
  PENDING,
  ACCEPTED,
  ON_THE_WAY,
  ARRIVED,
  IN_PROGRESS,
  COMPLETED,
  CANCELLED,
  DISPUTED;

  /// Retourne le nom formaté du statut.
  String get name {
    switch (this) {
      case PENDING:
        return 'pending';
      case ACCEPTED:
        return 'accepted';
      case ON_THE_WAY:
        return 'on_the_way';
      case ARRIVED:
        return 'arrived';
      case IN_PROGRESS:
        return 'in_progress';
      case COMPLETED:
        return 'completed';
      case CANCELLED:
        return 'cancelled';
      case DISPUTED:
        return 'disputed';
    }
  }

  /// Retourne le libellé du statut en français.
  String get label {
    switch (this) {
      case PENDING:
        return 'En attente';
      case ACCEPTED:
        return 'Acceptée';
      case ON_THE_WAY:
        return 'En route';
      case ARRIVED:
        return 'Sur place';
      case IN_PROGRESS:
        return 'En cours';
      case COMPLETED:
        return 'Terminée';
      case CANCELLED:
        return 'Annulée';
      case DISPUTED:
        return 'En litige';
    }
  }
}
