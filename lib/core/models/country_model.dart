/// Modèle de pays pour l'application FONACO
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final bool isDefault;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    this.isDefault = false,
  });

  /// Pays disponibles pour FONACO (Afrique de l'Ouest + Europe)
  static const List<Country> availableCountries = [
    Country(
      name: 'Bénin',
      code: 'BJ',
      dialCode: '+229',
      flag: '🇧🇯',
      isDefault: true,
    ),
    Country(
      name: 'Togo',
      code: 'TG',
      dialCode: '+228',
      flag: '🇹🇬',
    ),
    Country(
      name: 'Cameroun',
      code: 'CM',
      dialCode: '+237',
      flag: '🇨🇲',
    ),
    Country(
      name: 'Côte d\'Ivoire',
      code: 'CI',
      dialCode: '+225',
      flag: '🇨🇮',
    ),
    Country(
      name: 'France',
      code: 'FR',
      dialCode: '+33',
      flag: '🇫🇷',
    ),
    Country(
      name: 'Allemagne',
      code: 'DE',
      dialCode: '+49',
      flag: '🇩🇪',
    ),
  ];

  /// Pays par défaut (Bénin)
  static Country get defaultCountry => availableCountries.firstWhere(
    (country) => country.isDefault,
    orElse: () => availableCountries.first,
  );

  /// Trouve un pays par son code
  static Country? findByCode(String code) {
    try {
      return availableCountries.firstWhere(
        (country) => country.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Trouve un pays par son indicatif
  static Country? findByDialCode(String dialCode) {
    try {
      return availableCountries.firstWhere(
        (country) => country.dialCode == dialCode,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return '$flag $name ($dialCode)';
  }
}
