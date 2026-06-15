// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FONACO';

  @override
  String get navHome => 'Home';

  @override
  String get navMissions => 'Missions';

  @override
  String get navAgents => 'Agents';

  @override
  String get navLeBonCoin => 'LeBonCoin';

  @override
  String get navSettings => 'Settings';

  @override
  String get leBonCoinTitle => 'LeBonCoin';

  @override
  String get leBonCoinSubtitle => 'Expert artisans and local gems near you.';

  @override
  String get leBonCoinSearchHint => 'Search a place, an artisan…';

  @override
  String get leBonCoinMap => 'Map';

  @override
  String get leBonCoinList => 'List';

  @override
  String get leBonCoinWebsite => 'Website';

  @override
  String get leBonCoinEmpty => 'No results for this search.';

  @override
  String get filterAll => 'All';

  @override
  String get filterArtisans => 'Artisans';

  @override
  String get filterRestaurants => 'Restaurants';

  @override
  String get filterShops => 'Shops';

  @override
  String get filterLeisure => 'Outings';
}
