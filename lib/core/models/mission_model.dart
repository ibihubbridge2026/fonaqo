import 'package:flutter/material.dart';
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
  IN_PROGRESS_REVIEW('in_progress_review', 'En validation'),
  COMPLETED('completed', 'Terminée'),
  CANCELLED('cancelled', 'Annulée'),
  DISPUTED('disputed', 'En litige'),
  UNKNOWN('unknown', 'Inconnu');

  final String apiName;
  final String label;

  const MissionStatus(this.apiName, this.label);

  /// Conserve la compatibilité avec les appels existants `status.name`.
  String get name => apiName;

  /// Retourne la couleur de badge pour ce statut.
  Color get badgeColor {
    switch (this) {
      case MissionStatus.COMPLETED:
        return Colors.green;
      case MissionStatus.CANCELLED:
        return Colors.red;
      case MissionStatus.DISPUTED:
        return Colors.orange;
      case MissionStatus.PENDING:
      case MissionStatus.ACCEPTED:
      case MissionStatus.ON_THE_WAY:
      case MissionStatus.ARRIVED:
      case MissionStatus.IN_PROGRESS:
      case MissionStatus.IN_PROGRESS_REVIEW:
        return Colors.blue;
      case MissionStatus.UNKNOWN:
        return Colors.grey;
    }
  }

  /// Retourne la couleur de fond du badge (version douce avec opacité 0.2).
  Color get badgeBackgroundColor {
    return badgeColor.withOpacity(0.2);
  }
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
  final String? agentPhone;
  final String? address;
  final String? pickupAddress;
  final String? destinationAddress;
  final String? category;
  final String? avatarUrl;
  final double? agentRating;
  final int? agentCompletedMissions;
  final double? agentLatitude;
  final double? agentLongitude;
  final int? etaMinutes;
  final bool isVerified;
  final bool isConfidential;
  final bool isUrgent;
  final bool isVocalDescription;
  final double? serviceFee;
  final double? serviceAmount;
  final double? purchaseAmount;
  final String? agentEmail;
  final String? clientEmail;
  final String? targetAgentUsername;
  final List<String>? tags;
  final double? clientRating;

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
    this.agentPhone,
    this.address,
    this.pickupAddress,
    this.destinationAddress,
    this.category,
    this.avatarUrl,
    this.agentRating,
    this.agentCompletedMissions,
    this.agentLatitude,
    this.agentLongitude,
    this.etaMinutes,
    this.isVerified = false,
    this.isConfidential = false,
    this.isUrgent = false,
    this.isVocalDescription = false,
    this.serviceFee,
    this.serviceAmount,
    this.purchaseAmount,
    this.agentEmail,
    this.clientEmail,
    this.targetAgentUsername,
    this.tags,
    this.clientRating,
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
        agentPhone: json['agent_phone']?.toString(),
        address: json['address']?.toString(),
        pickupAddress: json['pickup_address']?.toString(),
        destinationAddress: json['destination_address']?.toString(),
        category: json['category']?.toString() ??
            _firstTagName(json['tags']),
        avatarUrl: json['avatar_url']?.toString(),
        agentRating: _readDouble(json['agent_rating']),
        agentCompletedMissions: _readInt(json['agent_completed_missions']),
        agentLatitude: _readDouble(json['agent_latitude']),
        agentLongitude: _readDouble(json['agent_longitude']),
        etaMinutes: _readInt(json['eta_minutes']),
        isVerified: _readBool(json['is_verified']),
        isConfidential: _readBool(json['is_confidential']),
        isUrgent: _readBool(json['is_urgent']),
        isVocalDescription: _readBool(json['is_vocal_description']),
        serviceFee: _readDouble(json['service_fee']),
        serviceAmount: _readDouble(json['service_amount']),
        purchaseAmount: _readDouble(json['purchase_amount']),
        agentEmail: json['agent_email']?.toString(),
        clientEmail: json['client_email']?.toString(),
        targetAgentUsername: json['target_agent_username']?.toString(),
        tags: _readStringList(json['tags']),
        clientRating: _readDouble(json['client_rating']),
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

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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

  static String? _firstTagName(dynamic tags) {
    if (tags is List && tags.isNotEmpty) {
      return tags.first.toString();
    }
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
      if (agentPhone != null) 'agent_phone': agentPhone,
      if (address != null) 'address': address,
      if (category != null) 'category': category,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (agentRating != null) 'agent_rating': agentRating,
      if (agentCompletedMissions != null)
        'agent_completed_missions': agentCompletedMissions,
      if (agentLatitude != null) 'agent_latitude': agentLatitude,
      if (agentLongitude != null) 'agent_longitude': agentLongitude,
      if (etaMinutes != null) 'eta_minutes': etaMinutes,
      if (targetAgentUsername != null)
        'target_agent_username': targetAgentUsername,
    };
  }

  /// Statuts faisant partie du cycle de vie actif agent.
  static const Set<MissionStatus> activeLifecycle = {
    MissionStatus.ACCEPTED,
    MissionStatus.ON_THE_WAY,
    MissionStatus.ARRIVED,
    MissionStatus.IN_PROGRESS,
    MissionStatus.IN_PROGRESS_REVIEW,
  };

  /// Délai priorité boost avant ouverture au pool général (minutes).
  static const int boostGateMinutes = 10;

  static bool isActiveLifecycle(MissionStatus status) =>
      activeLifecycle.contains(status);

  bool get hasAcceptedAgent =>
      agentName != null && agentName!.trim().isNotEmpty;

  bool isAssignedToAgent(String? agentUsername) {
    if (agentUsername == null || agentUsername.trim().isEmpty) return false;
    final target = targetAgentUsername?.trim();
    if (target == null || target.isEmpty) return false;
    return target.toLowerCase() == agentUsername.trim().toLowerCase();
  }

  /// Accepter : mission PENDING, sans agent, et ouverte ou assignée à moi.
  bool canAgentAccept(String? agentUsername) {
    if (status != MissionStatus.PENDING || hasAcceptedAgent) return false;
    final target = targetAgentUsername?.trim();
    if (target == null || target.isEmpty) return true;
    return isAssignedToAgent(agentUsername);
  }

  /// Refuser : uniquement si la mission m'a été attribuée explicitement.
  bool canAgentDecline(String? agentUsername) {
    return status == MissionStatus.PENDING &&
        !hasAcceptedAgent &&
        isAssignedToAgent(agentUsername);
  }

  /// Temps restant avant visibilité pool (agents sans boost).
  Duration? boostGateRemaining({bool hasActiveBoost = false}) {
    if (hasActiveBoost || createdAt == null) return null;
    if (status != MissionStatus.PENDING) return null;
    final unlockAt =
        createdAt!.add(const Duration(minutes: boostGateMinutes));
    final remaining = unlockAt.difference(DateTime.now());
    if (remaining.isNegative || remaining.inSeconds <= 0) return null;
    return remaining;
  }

  String formatCountdown(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      case 'in_progress_review':
        return MissionStatus.IN_PROGRESS_REVIEW;
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
    String? agentPhone,
    String? address,
    String? pickupAddress,
    String? destinationAddress,
    String? category,
    double? clientRating,
    double? agentRating,
    int? agentCompletedMissions,
    double? agentLatitude,
    double? agentLongitude,
    int? etaMinutes,
    String? targetAgentUsername,
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
      agentPhone: agentPhone ?? this.agentPhone,
      address: address ?? this.address,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      category: category ?? this.category,
      clientRating: clientRating ?? this.clientRating,
      agentRating: agentRating ?? this.agentRating,
      agentCompletedMissions:
          agentCompletedMissions ?? this.agentCompletedMissions,
      agentLatitude: agentLatitude ?? this.agentLatitude,
      agentLongitude: agentLongitude ?? this.agentLongitude,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      targetAgentUsername:
          targetAgentUsername ?? this.targetAgentUsername,
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
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7)
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
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
