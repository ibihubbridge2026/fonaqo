import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Écoute le retour réseau et déclenche une resynchronisation des données.
class ConnectivitySyncService {
  ConnectivitySyncService._();
  static final ConnectivitySyncService instance = ConnectivitySyncService._();

  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _wasOffline = false;
  Future<void> Function()? _onReconnect;

  bool get isListening => _subscription != null;

  /// Démarre l'écoute. [onReconnect] est appelé dès que la connexion revient.
  void start({required Future<void> Function() onReconnect}) {
    if (_subscription != null) return;
    _onReconnect = onReconnect;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (e) => _logger.w('Connectivity listener error: $e'),
    );

    _connectivity.checkConnectivity().then(_handleConnectivityChange);
    _logger.i('📡 ConnectivitySyncService démarré');
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _onReconnect = null;
    _wasOffline = false;
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final online = result != ConnectivityResult.none;

    if (!online) {
      _wasOffline = true;
      _logger.d('📴 Connexion perdue — données locales conservées');
      return;
    }

    if (_wasOffline && _onReconnect != null) {
      _wasOffline = false;
      _logger.i('📶 Connexion rétablie — resynchronisation…');
      try {
        await _onReconnect!();
      } catch (e) {
        _logger.w('Resync après reconnexion échouée: $e');
      }
    }
  }
}
