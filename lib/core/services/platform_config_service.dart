import 'package:logger/logger.dart';

import '../api/base_client.dart';
import '../constants/app_constants.dart';

/// Frais dynamiques mission (urgent / agent interne) depuis l'API.
class PlatformConfigService {
  PlatformConfigService._();
  static final PlatformConfigService instance = PlatformConfigService._();

  final BaseClient _client = BaseClient();
  final Logger _logger = Logger();

  double _feesUrgent = AppConstants.optionCost;
  double _feesConfidential = AppConstants.optionCost;
  bool _loaded = false;

  double get feesUrgent => _feesUrgent;
  double get feesConfidential => _feesConfidential;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final response = await _client.get('core/platform-fees/');
      final body = response.data;
      if (body is Map) {
        final urgent = body['fees_urgent'];
        final confidential = body['fees_confidential'];
        if (urgent is num) _feesUrgent = urgent.toDouble();
        if (confidential is num) _feesConfidential = confidential.toDouble();
      }
      _loaded = true;
    } catch (e, st) {
      _logger.w('Frais plateforme indisponibles, défaut local', error: e, stackTrace: st);
    }
  }
}
