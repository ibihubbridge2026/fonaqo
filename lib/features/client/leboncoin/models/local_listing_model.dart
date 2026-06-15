import 'package:fonaco/l10n/app_localizations.dart';

/// Fiche répertoriée sur LeBonCoin (artisan, restaurant, commerce, bon plan).
class LocalListingModel {
  final String id;
  final String name;
  final String category;
  final String? categoryLabel;
  final String specialty;
  final String description;
  final String address;
  final String city;
  final String district;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String email;
  final String? websiteUrl;
  final String? photoUrl;
  final double rating;
  final bool isFeatured;
  final List<String> tags;

  const LocalListingModel({
    required this.id,
    required this.name,
    required this.category,
    this.categoryLabel,
    this.specialty = '',
    this.description = '',
    this.address = '',
    this.city = 'Cotonou',
    this.district = '',
    this.latitude,
    this.longitude,
    this.phone = '',
    this.email = '',
    this.websiteUrl,
    this.photoUrl,
    this.rating = 4.0,
    this.isFeatured = false,
    this.tags = const [],
  });

  factory LocalListingModel.fromJson(Map<String, dynamic> json) {
    return LocalListingModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      categoryLabel: json['category_label']?.toString(),
      specialty: json['specialty']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Cotonou',
      district: json['district']?.toString() ?? '',
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      websiteUrl: json['website_url']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      rating: _readDouble(json['rating']) ?? 4.0,
      isFeatured: json['is_featured'] == true,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String get displayCategory => categoryLabel ?? category;

  String get locationLabel {
    if (district.isNotEmpty && city.isNotEmpty) return '$district, $city';
    return city.isNotEmpty ? city : address;
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}

enum LeBonCoinFilter {
  all,
  artisan,
  restaurant,
  shop,
  leisure,
}

extension LeBonCoinFilterX on LeBonCoinFilter {
  String label(AppLocalizations l10n) {
    switch (this) {
      case LeBonCoinFilter.all:
        return l10n.filterAll;
      case LeBonCoinFilter.artisan:
        return l10n.filterArtisans;
      case LeBonCoinFilter.restaurant:
        return l10n.filterRestaurants;
      case LeBonCoinFilter.shop:
        return l10n.filterShops;
      case LeBonCoinFilter.leisure:
        return l10n.filterLeisure;
    }
  }

  String? get apiCategory {
    switch (this) {
      case LeBonCoinFilter.all:
        return null;
      case LeBonCoinFilter.artisan:
        return 'artisan';
      case LeBonCoinFilter.restaurant:
        return 'restaurant';
      case LeBonCoinFilter.shop:
        return 'shop';
      case LeBonCoinFilter.leisure:
        return 'leisure';
    }
  }
}
