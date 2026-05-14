import 'package:logger/logger.dart';

/// Logger dédié au mapping JSON des missions.
final Logger _missionLogger = Logger();

/// Énumération des statuts de mission (Dart enhanced enum).
enum MissionStatus {
  PENDING('pending', 'En attente'),
  ACCEPTED('accepted', 'Acceptée'),
  ON_THE_WAY('on_the_way', 'En route'),
  ARRIVED('arrived', 'Sur place'),
  IN_PROGRESS('in_progress', 'En cours'),
  COMPLETED('completed', 'Terminée'),
  CANCELLED('cancelled', 'Annulée'),
  DISPUTED('disputed', 'En litige'),
  UNKNOWN('unknown', 'Inconnu');

  final String apiName;
  final String label;

  const MissionStatus(this.apiName, this.label);

  /// Conserve la compatibilité avec les appels existants `status.name`.
  String get name => apiName;
}

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
  /// Tous les champs disposent de valeurs par défaut pour résister aux
  /// payloads partiels. Les erreurs sont loguées pour diagnostic.
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    try {
      return MissionModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: _readDouble(json['price']) ?? 0.0,
        status: parseMissionStatus(json['status']?.toString()),
        latitude: _readDouble(json['latitude']),
        longitude: _readDouble(json['longitude']),
        createdAt: _readDate(json['created_at']),
        updatedAt: _readDate(json['updated_at']),
        clientName: json['client_name']?.toString(),
        agentName: json['agent_name']?.toString(),
        address: json['address']?.toString(),
        category: json['category']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        isVerified: _readBool(json['is_verified']),
        isConfidential: _readBool(json['is_confidential']),
        isUrgent: _readBool(json['is_urgent']),
        tags: _readStringList(json['tags']),
      );
    } catch (e, st) {
      _missionLogger.e(
        'MissionModel.fromJson a échoué — payload: $json',
        error: e,
        stackTrace: st,
      );
      // Retourne une mission « squelette » plutôt que de propager
      // une exception qui ferait crasher la liste entière.
      return MissionModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Mission',
        description: '',
        price: 0,
        status: MissionStatus.UNKNOWN,
      );
    }
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _readDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  static List<String>? _readStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  /// Convertit le MissionModel en JSON (requête API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'status': status.apiName,
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
