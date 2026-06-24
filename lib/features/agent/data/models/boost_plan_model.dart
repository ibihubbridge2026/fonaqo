/// Plan boost agent — parsing JSON tolérant (String / num).
class BoostPlanModel {
  final String id;
  final String name;
  final double price;
  final int durationHours;
  final double visibilityMultiplier;

  const BoostPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationHours,
    required this.visibilityMultiplier,
  });

  factory BoostPlanModel.fromJson(Map<String, dynamic> json) {
    return BoostPlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Boost',
      price: _readDouble(json['price_fcfa'] ?? json['price']) ?? 0,
      durationHours: _readInt(json['duration_hours'] ?? json['duration']) ?? 0,
      visibilityMultiplier:
          _readDouble(json['visibility_multiplier'] ?? json['multiplier']) ??
              1.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'price_fcfa': price,
        'duration_hours': durationHours,
        'visibility_multiplier': visibilityMultiplier,
      };

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
