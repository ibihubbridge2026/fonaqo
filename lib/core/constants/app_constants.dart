/// Constantes globales de l'application
class AppConstants {
  // Coordonnées GPS par défaut (Cotonou, Bénin)
  static const double defaultLatitude = 6.3703;
  static const double defaultLongitude = 2.3912;

  // Rayon de recherche par défaut en km
  static const double defaultSearchRadiusKm = 10.0;

  // Coûts par défaut
  static const double defaultServiceAmount = 1000.0;
  static const double defaultPurchaseAmount = 0.0;
  static const double minServiceAmount = 500.0;
  static const double optionCost = 500.0;

  // Timeout localisation GPS
  static const Duration locationTimeout = Duration(seconds: 15);

  // AppConstants ne doit pas être instancié
  AppConstants._();
}
