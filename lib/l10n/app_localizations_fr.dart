// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FONACO';

  @override
  String get navHome => 'Accueil';

  @override
  String get navMissions => 'Missions';

  @override
  String get navAgents => 'Agents';

  @override
  String get navLeBonCoin => 'LeBonCoin';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get leBonCoinTitle => 'LeBonCoin';

  @override
  String get leBonCoinSubtitle =>
      'Artisans experts et bons plans près de chez vous.';

  @override
  String get leBonCoinSearchHint => 'Rechercher un lieu, un artisan…';

  @override
  String get leBonCoinMap => 'Carte';

  @override
  String get leBonCoinList => 'Liste';

  @override
  String get leBonCoinWebsite => 'Site web';

  @override
  String get leBonCoinEmpty => 'Aucun résultat pour cette recherche.';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterArtisans => 'Artisans';

  @override
  String get filterRestaurants => 'Restaurants';

  @override
  String get filterShops => 'Commerces';

  @override
  String get filterLeisure => 'Sorties';
}
