/// Constantes globales de l'application
class AppConstants {
  // Coordonnées GPS par défaut (Abidjan, Côte d'Ivoire)
  static const double defaultLatitude = 5.3363;
  static const double defaultLongitude = -4.0260;
  
  // Coordonnées alternatives (Abidjan centre)
  static const double abidjanCenterLatitude = 6.3725;
  static const double abidjanCenterLongitude = 2.4318;
  
  // Rayon de recherche par défaut en km
  static const double defaultSearchRadiusKm = 10.0;
  
  // Coûts par défaut
  static const double defaultServiceAmount = 15000.0;
  static const double defaultPurchaseAmount = 0.0;
  static const double optionCost = 500.0;
  
  // Timeout localisation GPS
  static const Duration locationTimeout = Duration(seconds: 15);
  
  // AppConstants ne doit pas être instancié
  AppConstants._();
}
